#!/bin/bash

help_screen () {
	printf "HELP SCREEN"
	printf "./WSHC.sh <URL> <Status Code> <HTTP Method> \n"
}

if [[ $1 = "-h" ]]; then
	help_screen
	exit 1
fi

#Regex to check to makesure the url is in fact a url.
regexurl='^(https?|file|ftp):\/\/.*$'

#prints a nice little intro
printf "====================================================================\n"
figlet -f slant "Health Check"  
figlet "By Kahvi"
printf "with a side of ducks... Quack\n"
printf "====================================================================\n"
printf "\n\n\n\n\n\n\n"
echo "Welcome!"
#Check if arguments were given

#add checks for existing arguments

url=$1
statuscode=$2
httpmethod=$3

#Checks to make sure the url argument is a url, otherwise asks 
c=0
if [[ $url =~ $regexurl ]]
then
	printf ""
else
	while [ $c = 0 ]
	do
		printf "No correct URL supplied."
		printf "what is the URL for the site you would like to check? \n"
		help_screen
		read url
		if [[ $url =~ $regexurl ]]
		then
			c=1
		else
			c=0
		fi
	done
fi

c=0
if [[ ($statuscode -gt 199) && ($statuscode -lt 600) ]]
then
	printf ""
else
	while [ $c = 0 ]
	do
		printf "No correct URL entered."
		printf "\nWhat is the expected status code? Ex - 200) \n"
		help_screen
		read statuscode
		if [[ ($statuscode -gt 199) && ($statuscode -lt 600) ]]
		then
			c=1
		else
			c=0
		fi
	done
fi

#no check for method at the moment, there are a lot that could be used. If wanted later, use check against array.

#countdown to start
printf "\n\nAll lights are green! We are a go captain! \n"
sleep 2s
printf "Starting in 5 \n"
sleep 1s
printf "4 \n"
sleep 1s
printf "3 \n"
sleep 1s
printf "2 \n"
sleep 1s
printf "1 \n"
sleep 1s
clear

red=`tput setaf 1`
bg=`tput setab 7`
reset=`tput sgr 0`
n=0
count=0
time='  HTTP Status:	%{http_code}
	time_namelookup:  %{time_namelookup}s\n
        time_connect:  %{time_connect}s\n   
     time_appconnect:  %{time_appconnect}s\n 
    time_pretransfer:  %{time_pretransfer}s\n
       time_redirect:  %{time_redirect}s\n     
  time_starttransfer:  %{time_starttransfer}s\n   
          time_total:  %{time_total}s\n'
          
#Calculating Average Response Time
touch ./currenttime.txt
rm ./avgrsptime.txt && touch ./avgrsptime.txt
while [ $n -lt 5 ] ;
do
	echo "Calculating Average Response Time"
	curl -s -o /dev/null -I -w "%{time_total}" $url >> ./avgrsptime.txt
	n=$(($n+1))
	sleep 1s
done

#Average Response Time Calc
avg1=$(awk '{s+=$url}END{print s/NR}' ./avgrsptime.txt)
echo "Average is $avg1"
#Doubling Response Time for Unhealthy Response Time
average=$(awk "BEGIN {print ($avg1*2)}")
echo "$average"

#Checking HTTP Method
if [[ $httpmethod == "HEAD" ]] ; then
	method="-I"
else
	method="-X $httpmethod"
fi

#Monitoring Loop
while true
do
	#monitor HTTP status
	clear
	echo "==============================="
	echo "Monitoring $url"
	echo "Expected status $statuscode"
	echo "Using HTTP Method $httpmethod"
	echo "Average Response Time Was $avg1"
	echo "==============================="
	#HTTP Status Check
	curl -s -o /dev/null $method -w "%{http_code}\n%{time_total}" $url > status.txt
	if [[ $(head -1 ./status.txt) != $statuscode ]] ; then
		printf ${red}${bg}"WARNING Unexpected STATUS: "${reset}
		head -1 ./status.txt
		count=$(($count+1))
		printf "\r\n count: "$count
		notify-send -u critical -t 5000 "$count Unexpected Status Events"
	else
		echo "HTTP Status is $statuscode"
	fi
	#Response Time Check
	currenttime=$(tail -1 ./status.txt)
	if [[ $currenttime > $average ]] ; then
		printf ${red}${bg}"WARNING High Response Time: "${reset}
		echo $currenttime
		notify-send -u normal -t 5000 "High Response Time $currenttime"
	else
		echo "Current Response Time is $currenttime"
	fi
	
	sleep 10s
done
fi
