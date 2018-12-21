string dataset_label = ...;
int NbCores = ...;
range Cores = 1..NbCores;
int NbFreqs = ...;
range Freqs = 1..NbFreqs;
float Freq[Freqs] = ...;
int NbTasks = ...;
range Tasks = 1..NbTasks;
float Td = ...;
float a = ...; float b = ...; float c = ...;
float Dynpow_Exponent = ...;
float Etr = ...;
float Tsw = ...;
float Tbe;
execute
{
 if(Tsw > Etr / c)
 	Tbe = Tsw;
 else
    Tbe = Etr / c;
}
float Totalwork[Tasks] = ...; // total workload (total number of processor cycles) required by each task
int Adjmatrix[Tasks][Tasks] = ...; // adjacency matrix of task graph
int P_HEFT[Tasks] = ...; // processor assignment obtained for each task, obtained from HEFT algorithm
int O_HEFT[Tasks][Tasks] = ...; // ordering of tasks on processors, obtained from HEFT algorithm


dvar float+ Workratio[Tasks][Freqs]; // variable determining the distribution of required processor cycles for the complete execution of each task among available frequencies
dvar float+ Starttime[Tasks]; // variable determining start time of execution of each task
dvar boolean Processor[Cores][0..(NbTasks+1)]; // variable determining task-to-processor assignment
dvar boolean Ordering[Cores][0..(NbTasks)][1..(NbTasks+1)]; // variable determining ordering of tasks on processors
dvar boolean Used[Cores];// variable determining whether a processor is used for scheduling of tasks or not

/* utility decision variables for the second term of the objective function */
dvar float+ Mul1[Cores][Tasks][Tasks]; // Mul1 == (s(u)+dur(u)) * Yk(u,v)
dvar float+ Mul2[Tasks]; // Mul2 == (1 - sum(Yk(0,v))) * itv
dvar boolean Switch[Tasks];
dvar float+ Mul3[Tasks]; // Mul3 == (1 - Switch[v]) * Mul2[v]

/* utility decision variables for the third term of the objective function */
dvar float+ Mul4[Cores][Tasks]; // Mul4 == Yk(0,v) * Sv
dvar float+ Mul5[Cores][Tasks]; // Mul5 == (s(u)+dur(u)) * Yk(u,n+1)
dvar boolean Big_Switch[Cores];
dvar float+ Mul6[Cores]; // Mul6 == (1 - Big_Switch[k]) * (first_idletime[k] + last_idletime[k]) 
dvar float+ Mul7[Cores]; // Mul7 == Big_Switch[k] * Used[k]




dexpr float Duration[u in Tasks] = sum( i in Freqs ) ( Workratio[u][i] / Freq[i] );
dexpr float idletime[v in Tasks] = Starttime[v] - sum ( k in Cores ) ( sum ( u in Tasks ) ( Mul1[k][u][v] ));
dexpr float first_idletime[k in Cores] = sum (v in Tasks) (Mul4[k][v]);
dexpr float last_idletime[k in Cores] = Td - sum (u in Tasks) (Mul5[k][u]);
dexpr float NbSwitches = sum( v in Tasks )(Switch[v]) + sum( k in Cores )(Mul7[k]);


/* The following simulation parameters determine the maximum time limit allowed for CPLEX engine 
   to search for the optimum solution, and the working memory allocated to CPLEX engine (which should be set based on physical memory 
   of the user's hardware). Both parameters can be modified according to user's preferences. */
execute
{
cplex.tilim = 5400.00;
cplex.workmem = 16384.0
}

/* The following code block determines the minimization objective function (Eq. 19 in the paper). */
minimize
  sum( u in Tasks ) 
    (
    a * sum( i in Freqs ) ( Workratio[u][i] * Freq[i]^(Dynpow_Exponent-1) ) + 
    b * sum( i in Freqs ) ( Workratio[u][i] ) + 
    c * sum( i in Freqs ) ( Workratio[u][i] / Freq[i] )
    )
  +
  sum( v in Tasks )
   (
   Switch[v] * Etr + Mul3[v] * c
   )
  +
  sum( k in Cores )
   (
   Mul7[k] * Etr + Mul6[k] * c
   )
  ;


/* The following constratins (inside "subject to {...}") determine the constraints of the optimization problem. */
subject to {

  forall( u in Tasks )
    ctTotalwork:  
      sum( i in Freqs ) 
        Workratio[u][i] == Totalwork[u];
        
  forall ( u in Tasks, v in Tasks )
    ctPrecedence:
      if (Adjmatrix[u][v] == 1)
		Starttime[u] + Duration[u]  <= Starttime[v];

  
  forall ( u in Tasks, v in Tasks, k in Cores )
    ctNonpreemption:
      Starttime[u] + Duration[u] - ((3 - Processor[k][u] - Processor[k][v] - Ordering[k][u][v]) * Td) <= Starttime[v];

      
  forall ( u in Tasks )
    ctHarddeadline:
      Starttime[u] + Duration[u] <= Td;
     
   forall ( u in Tasks )
     ctProcessorassignment_Feasibility:
       sum( k in Cores )
         Processor[k][u] == 1;
         
   forall (k in Cores)
     ctFirsttask_Processorassignment_Feasibility:
     	Processor[k][0] == 1;        

   forall (k in Cores)
     ctLasttask_Processorassignment_Feasibility:
       Processor[k][NbTasks+1] == 1;
         
  forall (k in Cores )
    forall (u in 0..NbTasks)
    ctNexttaskordering_Feasibility:
      sum( v in 1..(NbTasks+1) )
        Ordering[k][u][v] == Processor[k][u];
        

  forall (k in Cores )
    forall(v in 1..(NbTasks+1))
    ctPrevtaskordering_Feasibility:
      sum( u in 0..NbTasks )
        Ordering[k][u][v] == Processor[k][v];

        
   forall (u in Tasks, k in Cores)
     Ordering[k][u][u] == 0;

     

   forall(u in Tasks)
     Processor[P_HEFT[u]][u] == 1;
   
  forall ( u in Tasks, v in Tasks )
      if (O_HEFT[u][v] == 1)
        Ordering[P_HEFT[u]][u][v] == 1;       
       


// Mul1 constraints
  forall (k in Cores)
    forall (u in Tasks)
      forall (v in Tasks)
        Mul1[k][u][v] <= Ordering[k][u][v] * Td;
        
  forall (k in Cores)
    forall (u in Tasks)
      forall (v in Tasks)
        Mul1[k][u][v] - (Starttime[u] + Duration[u]) <= 0;
        

  forall (k in Cores)
    forall (u in Tasks)
      forall (v in Tasks)
        Mul1[k][u][v] - Ordering[k][u][v] * Td - (Starttime[u] + Duration[u]) + Td >= 0;                  
      
// Mul2 constraints
  forall (v in Tasks)
    Mul2[v] <= (1 - sum ( k in Cores ) ( Ordering[k][0][v] )) * Td;
    
  forall (v in Tasks)
    Mul2[v] - idletime[v] <= 0;
    
  forall (v in Tasks)
    Mul2[v] - (1 - sum ( k in Cores ) ( Ordering[k][0][v] )) * Td - idletime[v] + Td >= 0;
     
// Switch constraints
  forall (v in Tasks)
    ((Mul2[v] - Tbe) / Td) <= Switch[v];

  forall (v in Tasks)
    Switch[v] <= Mul2[v] / Tbe;

    
// Mul3 constraints
  forall (v in Tasks)
    Mul3[v] <= (1 - Switch[v]) * Td;
    
  forall (v in Tasks)
    Mul3[v] - Mul2[v] <= 0;
    
  forall (v in Tasks)
    Mul3[v] - (1 - Switch[v]) * Td - Mul2[v] + Td >= 0;

// Mul4 constraints
  forall (k in Cores)
    forall (v in Tasks)
      Mul4[k][v] <= Ordering[k][0][v] * Td;
    
  forall (k in Cores)
    forall (v in Tasks)    
  	  Mul4[k][v] - Starttime[v] <=0;
  	
  forall (k in Cores)  	    
    forall (v in Tasks)
      Mul4[k][v] - Ordering[k][0][v] * Td - Starttime[v] + Td >= 0;
    
// Mul5 constraints
  forall (k in Cores)
    forall (u in Tasks)
      Mul5[k][u] <= Ordering[k][u][NbTasks+1] * Td;
    
  forall (k in Cores)
    forall (u in Tasks)    
  	  Mul5[k][u] - (Starttime[u] + Duration[u]) <= 0;
  	
  forall (k in Cores)  	    
    forall (u in Tasks)
      Mul5[k][u] - Ordering[k][u][NbTasks+1] * Td - (Starttime[u] + Duration[u]) + Td >= 0;
    
// Big_Switch constraints  
  forall (k in Cores)
    (((first_idletime[k] + last_idletime[k]) - Tbe) / Td) <= Big_Switch[k];

  forall (k in Cores)
    Big_Switch[k] <= (first_idletime[k] + last_idletime[k]) / Tbe;
    
// Mul6 constraints
  forall (k in Cores)
    Mul6[k] <= (1 - Big_Switch[k]) * Td;
  
  forall (k in Cores)
    Mul6[k] - (first_idletime[k] + last_idletime[k]) <= 0;
  
  forall (k in Cores)
    Mul6[k] - (1 - Big_Switch[k]) * Td - (first_idletime[k] + last_idletime[k]) + Td >= 0;
  
// "Used" constraints
  forall (k in Cores)
    (((first_idletime[k] + last_idletime[k]) - Td) / Td) <= (1-Used[k]);

  forall (k in Cores)
    (1-Used[k]) <= (first_idletime[k] + last_idletime[k]) / Td;

// Mul7 constraints
  forall (k in Cores)
    Mul7[k] <= Big_Switch[k];
    
  forall (k in Cores)
    Mul7[k] <= Used[k];
    
  forall (k in Cores)
    Big_Switch[k] + Used[k] - Mul7[k] <= 1;    

}

main {
  thisOplModel.generate();
  cplex.solve(); 
  
 /* The following commands generate a .txt file containing simulation results, including
    total energy consumption, idle time characteristics, and usage of processors. */
  var ofile = new IloOplOutputFile("Heuristic_"+thisOplModel.dataset_label+".txt");
  ofile.writeln(thisOplModel.printExternalData());
  ofile.writeln(thisOplModel.printInternalData());
  ofile.writeln(thisOplModel.printSolution());
  ofile.writeln("];");
  
  ofile.writeln("Duration = [");
  for(var u in thisOplModel.Tasks){
    ofile.writeln(thisOplModel.Duration[u]);
  }
  ofile.writeln("]");
  
  ofile.writeln("NbSwitches = [");
  ofile.writeln(thisOplModel.NbSwitches);
  ofile.writeln("]");
  
  var NbIdles = 0;
  for (var u in thisOplModel.Tasks){
    if(thisOplModel.Mul2[u] > 0) {
      NbIdles = NbIdles + 1; 	   
    } 
  }
  for (var k in thisOplModel.Cores){
    if((thisOplModel.first_idletime[k] + thisOplModel.last_idletime[k]) > 0){
      NbIdles = NbIdles + 1;    
    }  
  }
  ofile.writeln("NbIdles = [");
  ofile.writeln(NbIdles)
  ofile.writeln("]")
  
  var TotalIdles = 0;
  for (var u in thisOplModel.Tasks){
    if(thisOplModel.Mul2[u] > 0) {
      TotalIdles = TotalIdles + thisOplModel.Mul2[u]; 	   
    } 
  }
  for (var k in thisOplModel.Cores){
    if(thisOplModel.Used[k] > 0){
      if((thisOplModel.first_idletime[k] + thisOplModel.last_idletime[k]) > 0){
        TotalIdles = TotalIdles + thisOplModel.first_idletime[k] + thisOplModel.last_idletime[k];    
      }
    }       
  }
  ofile.writeln("TotalIdles = [");
  ofile.writeln(TotalIdles)
  ofile.writeln("]")  
  
  ofile.close();
  
  /* The following commands generate a .m file for the sake of visualizing results in MATLAB. */
  var ofile = new IloOplOutputFile("Heuristic_"+thisOplModel.dataset_label+".m");
  ofile.writeln("%%%%%%%%%%%%%%%%%%%% Info of the Desired Solved Model %%%%%%%%%%%%%%%%%%%%");
  
  ofile.writeln("NbCores = "+thisOplModel.NbCores+";");
  
  ofile.writeln("NbTasks = "+thisOplModel.NbTasks+";");
  
  ofile.writeln("Td = "+thisOplModel.Td+";");
  
  ofile.write("Starttime = [ ");
  for(var u in thisOplModel.Tasks){
     ofile.write(thisOplModel.Starttime[u]+" ");
  }
  ofile.writeln("];");
  
  ofile.write("Duration = [ ");
  for(var u in thisOplModel.Tasks){
    ofile.write(thisOplModel.Duration[u]+" ");
  }
  ofile.writeln("];");
  
  ofile.writeln("Processor = [");
  for(var k in thisOplModel.Cores){
    ofile.write("[ ");
    ofile.write(thisOplModel.Processor[k][0]+" ");
  	for(var u in  thisOplModel.Tasks){
      ofile.write(thisOplModel.Processor[k][u]+" ");    
    }
    ofile.write(thisOplModel.Processor[k][thisOplModel.NbTasks+1]+" ");
    ofile.writeln("]");
  }
  ofile.writeln("];");
  ofile.writeln("%%%%%%%%%%%%%%%%%%%% Plotting the Obtained Schedule of Tasks %%%%%%%%%%%%%%%%%%%%");
  ofile.writeln("Y_Tasks = zeros(1,NbTasks);% Y_Tasks represent the y-axis value each task should be plotted with (corresponding to its processor assignment)");
  ofile.writeln("for u = 2:(NbTasks+1)");
  ofile.writeln("    for k = 1:NbCores");
  ofile.writeln("        if Processor(k,u) == 1");
  ofile.writeln("            Y_Tasks(u-1) = 10 * k;");
  ofile.writeln("        end");
  ofile.writeln("    end");
  ofile.writeln("end");
  
  ofile.writeln("figure();");
  ofile.writeln("title('Heuristic Scheduling for "+thisOplModel.dataset_label+"')");
  ofile.writeln("for k = 1:NbCores");
  ofile.writeln("    text(-0.15,10 * k,sprintf('Processor%d', k),'HorizontalAlignment','right');");
  ofile.writeln("    hold on;");
  ofile.writeln("end");
  ofile.writeln("for u = 1:NbTasks");
  ofile.writeln("    plot([Starttime(u) , (Starttime(u)+Duration(u))] , [Y_Tasks(u) , Y_Tasks(u)] , '-*');");
  ofile.writeln("    text((Starttime(u)+Duration(u)/2),Y_Tasks(u),sprintf('Task%d', u),'HorizontalAlignment','center');");
  ofile.writeln("    hold on;");
  ofile.writeln("end")
  
  ofile.writeln("xlabel(sprintf('Time(ms), Td = %d ms', Td));");
  ofile.writeln("set(gca,'ytick',[]);")
  ofile.writeln("xlim([0 Td]);");
  ofile.writeln("ylim([0 (NbCores+1)*10]);");
  
  ofile.close();
}
