param( [Switch] $Delete)

function wsl2-network {

    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Switch]$Delete
    )

    $MC=Measure-Command {

        ipconfig /flushdns
        nbtstat -R

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo;
        $pinfo.FileName = "bash.exe";
        $pinfo.RedirectStandardError = $true;
        $pinfo.RedirectStandardOutput = $true;
        $pinfo.UseShellExecute = $false;
        $pinfo.Arguments = "-c ifconfig eth0 | grep 'inet '";
        $p = New-Object System.Diagnostics.Process;
        $p.StartInfo = $pinfo;
        $p.Start() | Out-Null;
        $p.WaitForExit();
        $stdout = $p.StandardOutput.ReadToEnd().Replace("`n","").Replace("  "," ");
        $stderr = $p.StandardError.ReadToEnd();
        Write-Host "stdout: $stdout";
        Write-Host "stderr: $stderr";
        Write-Host "exit code: " + $p.ExitCode;

        $remoteport = $stdout;

        $found = $found=($remoteport -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' ? $true : $false);

        if( $found ){
          $remoteport = $matches[0];
        } else{
          wsl --shutdown;
          Get-Service LxssManager | Restart-Service -Force;

          $pinfo = New-Object System.Diagnostics.ProcessStartInfo;
          $pinfo.FileName = "bash.exe";
          $pinfo.RedirectStandardError = $true;
          $pinfo.RedirectStandardOutput = $true;
          $pinfo.UseShellExecute = $false;
          $pinfo.Arguments = "-c ifconfig eth0 | grep 'inet '";
          $p = New-Object System.Diagnostics.Process;
          $p.StartInfo = $pinfo;
          $p.Start() | Out-Null;
          $p.WaitForExit();
          $stdout = $p.StandardOutput.ReadToEnd().Replace("`n","").Replace("  "," ");
          $stderr = $p.StandardError.ReadToEnd();
          Write-Host "stdout: $stdout";
          Write-Host "stderr: $stderr";
          Write-Host "exit code: " + $p.ExitCode;

          $remoteport = $stdout;

          $found = $found=($remoteport -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' ? $true : $false);
          if( $found ){
             $remoteport = $matches[0];
          } else{
            echo "The Script Exited, the ip address of WSL 2 cannot be found";
            exit;
          }
        }

        #[Ports]

        #All the ports you want to forward separated by coma
        $ports=@()
        $ports+=587;
        $ports+=1120;
        $ports+=1122;
        $ports+=1234;
        $ports+=1235;
        $ports+=1236;
        $ports+=1237;
        $ports+=1238;
        $ports+=1239;
        $ports+=1433;
        $ports+=1434;
        $ports+=1521;
        $ports+=2250;
        $ports+=2251;
        $ports+=2252;
        $ports+=2253;
        $ports+=2254;
        $ports+=2255;
        $ports+=2256;
        $ports+=2257;
        $ports+=2258;
        $ports+=2259;
        $ports+=3000;
        $ports+=3331;
        $ports+=3332;
        $ports+=3333;
        $ports+=3334;
        $ports+=3335;
        $ports+=3336;
        $ports+=3337;
        $ports+=3338;
        $ports+=3339;
        $ports+=3388;
        $ports+=3389;
        $ports+=3390;
        $ports+=3398;
        $ports+=3399;
        $ports+=5910;
        $ports+=5911;
        $ports+=7010;
        $ports+=8118;
        $ports+=8119;
        $ports+=8080;
        $ports+=8083;
        $ports+=8443;
        $ports+=9050;
        $ports+=9610;
        $ports+=9898;
        $ports+=9899;
        $ports+=9901;
        $ports+=9915;
        $ports+=9999;
        $ports+=9259;
        $ports+=10000;
        $ports+=30100;
        $ports+=62200;

        #[Static ip]
        #You can change the addr to your ip config to listen to a specific address
        $addr='0.0.0.0';
        $ports_a = $ports -join ",";

        #Remove Firewall Exception Rules
        iex "Remove-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' ";

        #adding Exception Rules for inbound and outbound Rules
        iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Outbound -LocalPort $ports_a -Action Allow -Protocol TCP";
        iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Inbound -LocalPort $ports_a -Action Allow -Protocol TCP";

        [int]$nPercent=0
        [int]$nProgress=0

        for( $i = 0; $i -lt $ports.length; $i++ ){

          $nProgress++
          $nPercent=[int](($nProgress/$ports.length)*100)

          $port = $ports[$i];

          $msg="netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$addr";

          Write-Progress -id 0 `
                               -Activity "Processando [$i]/[$($ports.length)]" `
                               -PercentComplete $nPercent `
                               -Status ("$nPercent % "+$msg.Substring(26).Replace("listen",""))`
                               -CurrentOperation $msg.Substring(26).Replace("listen","");
          iex $msg;

          If(!$Delete) {

              $msg="netsh interface portproxy add v4tov4 listenport=$port listenaddress=$addr connectport=$port connectaddress=$remoteport";

              Write-Progress -id 1 `
                               -Activity "Processando [$i]/[$($ports.length)]" `
                               -PercentComplete $nPercent `
                               -Status ("$nPercent % "+$msg.Substring(26).Replace("listen",""))`
                               -CurrentOperation $msg.Substring(26).Replace("listen","");

              iex $msg;

          }

        }
    }

    $MC | Out-Null

}

Clear-Host

wsl2-network $Delete

Clear-Host
