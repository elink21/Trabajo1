#!/bin/bash


#auxiliar functions section

  function printHeaderData {

  	#All the mem information is located in the file meminfo
  	readarray memData < "/proc/meminfo";
  	#CPU percentage is the 2nd parameter of this function
  	echo "CPU $2"

  	#And # of process is the first one
  	echo -n "Procesos activos : $1 "

  	#Since the data have another fields, we need to filter them.
  	totalMemory=$(echo "${memData[0]}" | sed 's/[^0-9]*//g')

  	freeMemory=$(echo "${memData[1]}" | sed 's/[^0-9]*//g')	

  	#We can express usedMemory as the diff of total and free mem
  	usedMemory=$(expr $totalMemory - $freeMemory)


  	echo -n " -- Memoria total= $totalMemory kb"
  	echo -n " -- Memoria libre= $freeMemory kb"
  	echo " -- Memoria usada= $usedMemory kb"
  	echo
  }




  function printProcessData {

  	#ls will retrieve all the directories, but we need to use grep in order to filter 
  	#only the numeric ones.
	processCommand=$(ls /proc -t | grep '^[0-9]*$');

	#And then we will save it in an array
	proccessArray=();
	

	#Total memory will be used for Mem percentage calcs.
	readarray memData < "/proc/meminfo";

	totalMemory=$(echo "${memData[0]}" | sed 's/[^0-9]*//g')
	
	#For each process we need to validate that it 
	#exists and the we append it to processArray
	for i in $processCommand; do
		if [ -d "/proc/${i%%/}" ]; then
			processArray+=("${i%%/}");
		fi
 	done
 	

 	#totalTimes1() is the first read of CPU  times
	totalTimes1=() 	
	
	#Then we need to fill totalTimes1() and wait 1s
	for i in ${processArray[@]}; do
	
		readarray lines < "/proc/$i/stat";
		
		statData=();

	  	for x in ${lines[@]}; do	
	  		statData+=("$x")
  		done

		totalTime=0
	
		let " totalTime= ${statData[14]} + ${statData[15]}"
		
		totalTimes1+=("$totalTime")
	done 	

	sleep 1
	
	j=0
	
	
	#Total CPU is the summatory of each PID's CPU percentage
	totalCPU=0
	
	for i in ${processArray[@]}; do
	

		readarray lines < "/proc/$i/stat";
		
		statData=();

	  	for x in ${lines[@]}; do	
	  		statData+=("$x")
  		done

		totalTime=0
	
		let " totalTime= ${statData[14]} + ${statData[15]}"
		
		
		#Getting the diff of totalTime after sleep 1s 

		cpuPercentage=$(bc <<< "scale=2;  $totalTime - ${totalTimes1[j]}")
		
		#Since getconf CLK_TCK = 100 this is used in order to get %
		cpuPercentage=$(bc <<< "scale=2; $cpuPercentage / 10")
		
		totalCPU=$(bc <<< "scale=2; $cpuPercentage + $totalCPU")
		
		#Memory PID is expressed in bytes, so we convert it to kb
		memoryPID=`expr ${statData[22]} / 1024`
	  	
	  	#And with total mem we get a %
	  	memPercentage=$(bc <<< "scale=2;  $memoryPID / $totalMemory * 100")
	
		#getting username through user id
		uid=$(awk '/^Uid:/{print $2}' /proc/"$i/"status)

		uname=$(getent passwd "$uid" | awk -F: '{printf $1 }')	

		file="pidData.txt"
		
		#The information is redirected to a file, so we can use sort it
		echo -e "${statData[0]} \t ${statData[17]} \t\t ${statData[2]} \t $cpuPercentage\t $memPercentage \t $totalTime \t\t ${statData[1]} \t\t "$uname" \t\t $memoryPID  " >> $file
		
		let "j= $j + 1"
	done 

	#In the standard output we print header data
	printHeaderData "${#processArray[@]}" "$totalCPU";
	
	echo -e "PID \t Prior \t\t Estado  %CPU \t %MEM \t Tiempo \t Commando \t\t Usuario \t Memoria   "
	echo


}

#end auxiliar functions section

#Cleaning auxiliar file
truncate -s 0 "pidData.txt"

clear

printProcessData

#We use this in order to sort information by %CPU in reverse order.
sort -nrk 4 /home/sistemas/data.txt | head -n 10




