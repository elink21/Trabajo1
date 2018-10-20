#!/bin/bash


#auxiliar functions section

  function printHeaderData {
  	readarray memData < "/proc/meminfo";
  	echo "CPU $2"
  	echo -n "Procesos activos : $1 "

  	totalMemory=$(echo "${memData[0]}" | sed 's/[^0-9]*//g')

  	freeMemory=$(echo "${memData[1]}" | sed 's/[^0-9]*//g')	

  	usedMemory=$(expr $totalMemory - $freeMemory)


  	echo -n " -- Memoria total= $totalMemory kb"
  	echo -n " -- Memoria libre= $freeMemory kb"
  	echo " -- Memoria usada= $usedMemory kb"
  	echo
  }




  function printProcessData {

	processCommand=$(ls /proc -t | grep '^[0-9]*$');

	proccessArray=();
	
	readarray memData < "/proc/meminfo";

	totalMemory=$(echo "${memData[0]}" | sed 's/[^0-9]*//g')
	
	for i in $processCommand; do
		if [ -d "/proc/${i%%/}" ]; then
			processArray+=("${i%%/}");
		fi
 	#echo ${i%%/};
 	done
 	

	totalTimes1=() 	
	
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
		
		memoryPID=`expr ${statData[22]} / 1024`
	  	
	  	memPercentage=$(bc <<< "scale=2;  $memoryPID / $totalMemory * 100")
	
		#getting username through user id
		uid=$(awk '/^Uid:/{print $2}' /proc/"$i/"status)

		uname=$(getent passwd "$uid" | awk -F: '{printf $1 }')	

		file="/home/sistemas/data.txt"
		
		echo -e "${statData[0]} \t ${statData[17]} \t\t ${statData[2]} \t $cpuPercentage\t $memPercentage \t $totalTime \t\t ${statData[1]} \t\t "$uname" \t\t $memoryPID  " >> $file
		
		let "j= $j + 1"
	done 

	printHeaderData "${#processArray[@]}" "$totalCPU";
	
	echo -e "PID \t Prior \t\t Estado  %CPU \t %MEM \t Tiempo \t Commando \t\t Usuario \t Memoria   "
	echo


}

#end auxiliar functions section


truncate -s 0 "/home/sistemas/data.txt"

clear

printProcessData

sort -nrk 4 /home/sistemas/data.txt | head -n 10




