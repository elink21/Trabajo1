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
  	
  	read utime idltime <  "/proc/uptime"
  	
  	
  	read cpu a b c d e f g h i j< "/proc/stat"
  	
  	let "firstTotal= $a + $b + $c + $d + $e + $f + $g + $h + $i + $j"
  	
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
	
	echo "Primer lectura de tiempos"
	
	#Then we need to fill totalTimes1() and wait 1s
	for i in ${processArray[@]}; do
	
		readarray lines < "/proc/$i/stat";
		
		statData=();

	  	for x in ${lines[@]}; do	
	  		statData+=("$x")
  		done

		totalTime=0
	
		let " totalTime= ${statData[13]} + ${statData[14]}"
		
		totalTimes1+=("$totalTime")
	done 	

	sleep 1
	
	read cpu a b c d e f g h i j < "/proc/stat"
  	
  	let "secondTotal= $a + $b + $c + $d + $e + $f + $g + $h + $i + $j"
  	
  	let "diffTime = $secondTotal - $firstTotal"
	
	j=0
	
	clear 
	
	echo "Segunda lectura de tiempos y creacion de pidData.txt..."
	
	
	#Total CPU is the summatory of each PID's CPU percentage
	totalCPU=0
	
	for i in ${processArray[@]}; do
	

		readarray lines < "/proc/$i/stat";
		
		statData=();

	  	for x in ${lines[@]}; do	
	  		statData+=("$x")
  		done

		totalTime=0
	
		let " totalTime= ${statData[13]} + ${statData[14]}"
		
		
		#Getting the diff of totalTime after sleep 1s 
		
		let "cpuPercentage = $totalTime - ${totalTimes1[j]}"
	
		
		let "cpuPercentage = 100 *  $cpuPercentage / $diffTime  "
		
		
		let "totalCPU = $cpuPercentage + $totalCPU"
		
		
		#Memory PID is expressed in bytes, so we convert it to kb
		
		let "memoryPID =  ${statData[22]} / 1024 "
	  	
	  	#And with total mem we get a %
	  	
	  	let "memPercentage = 100 *  $memoryPID / $totalMemory "
	  
	
		#getting username through user id
		uid=$(awk '/^Uid:/{print $2}' /proc/"$i/"status)

		uname=$(getent passwd "$uid" | awk -F: '{printf $1 }')	

		file="pidData.txt"
		
		#The information is redirected to a file, so we can use sort it
		echo -e "${statData[0]} \t ${statData[17]} \t\t ${statData[2]} \t $cpuPercentage\t $memPercentage \t $totalTime \t\t ${statData[1]} \t\t "$uname" \t\t $memoryPID  " >> $file
		
		let "j= $j + 1"
	done 
	
	clear
	
	if [ $totalCPU -gt 100 ] # integer ops can make $totalCPU reach a value gt 100, so we adjust it 
	
	then
		let "totalCPU = 100"
	fi
	#In the standard output we print header data
	printHeaderData "${#processArray[@]}" "$totalCPU";
	
	echo -e "PID \t Prior \t\t Estado  %CPU \t %MEM \t Tiempo \t Commando \t\t Usuario \t Memoria   "
	echo


}

#end auxiliar functions section

#Cleaning auxiliar file
echo "Limpiando archivo pidData.txt"
truncate -s 0 "pidData.txt"

clear

printProcessData

#We use this in order to sort information by %CPU in reverse order.
sort -nrk 4 pidData.txt | head -n 10




