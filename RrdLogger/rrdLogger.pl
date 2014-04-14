#!/usr/bin/perl
#---------------------------------------------------------------------------------------------------
# Script to measure the temperatures and add them into a rrd database.
# 
# 
#---------------------------------------------------------------------------------------------------
use RRDs;

sub CreateAllGraphs
{
  # creates the graph
  # input: $_[0]: interval (ie, day, week, month, year)
  #        $_[1]: $rrd
  #        $_[2]: $img
  
  my $rrd = $_[1];
  my $img = $_[2];
  
  RRDs::graph "$img/logger-all-$_[0].png","--lazy","-s -1$_[0]",
              "-t Temperatures in and around the PausHaus",
	      "-h", "300", "-w", "600","-a", "PNG","-v Temperature [degrees C]",
#             define graph one
	      "DEF:officetemp=$rrd/logger.rrd:office-temp:AVERAGE",
	      "LINE2:officetemp#FF0000:Temperature-Office    ",
	      "GPRINT:officetemp:MIN:  Min\\: %4.1lf",
	      "GPRINT:officetemp:MAX: Max\\: %4.1lf",
	      "GPRINT:officetemp:AVERAGE: Avg\\: %4.1lf",
	      "GPRINT:officetemp:LAST: Current\\: %4.1lf  [degrees C]\\n",
#             define graph two
	      "DEF:livingroomtemp=$rrd/logger.rrd:livingroom-temp:AVERAGE",
	      "LINE3:livingroomtemp#00FF00:Temperature-LivingRoom",
	      "GPRINT:livingroomtemp:MIN:  Min\\: %4.1lf",
	      "GPRINT:livingroomtemp:MAX: Max\\: %4.1lf",
	      "GPRINT:livingroomtemp:AVERAGE: Avg\\: %4.1lf",
	      "GPRINT:livingroomtemp:LAST: Current\\: %4.1lf  [degrees C]\\n",
#             define graph three
	      "DEF:outdoortemp=$rrd/logger.rrd:outdoor-temp:AVERAGE",
	      "LINE3:outdoortemp#0000FF:Temperature-Outdoor   ",
	      "GPRINT:outdoortemp:MIN:  Min\\: %4.1lf",
	      "GPRINT:outdoortemp:MAX: Max\\: %4.1lf",
	      "GPRINT:outdoortemp:AVERAGE: Avg\\: %4.1lf",
	      "GPRINT:outdoortemp:LAST: Current\\: %4.1lf  [degrees C]\\n";
    
  if ($ERROR = RRDs::error) {
    print "$0: unable to generate $_[0] graph: $ERROR\n";
  }
}

sub CreateInsideGraphs
{
  # creates the graph
  # input: $_[0]: interval (ie, day, week, month, year)
  #        $_[1]: $rrd
  #        $_[2]: $img
  
  my $rrd = $_[1];
  my $img = $_[2];
  
  RRDs::graph "$img/logger-inside-$_[0].png","--lazy","-s -1$_[0]",
              "-t Temperatures in and around the PausHaus",
	      "-h", "300", "-w", "600","-a", "PNG","-v Temperature [degrees C]",
#             define graph one
	      "DEF:officetemp=$rrd/logger.rrd:office-temp:AVERAGE",
	      "LINE2:officetemp#FF0000:Temperature-Office    ",
	      "GPRINT:officetemp:MIN:  Min\\: %4.1lf",
	      "GPRINT:officetemp:MAX: Max\\: %4.1lf",
	      "GPRINT:officetemp:AVERAGE: Avg\\: %4.1lf",
	      "GPRINT:officetemp:LAST: Current\\: %4.1lf  [degrees C]\\n",
#             define graph two
	      "DEF:livingroomtemp=$rrd/logger.rrd:livingroom-temp:AVERAGE",
	      "LINE3:livingroomtemp#00FF00:Temperature-LivingRoom",
	      "GPRINT:livingroomtemp:MIN:  Min\\: %4.1lf",
	      "GPRINT:livingroomtemp:MAX: Max\\: %4.1lf",
	      "GPRINT:livingroomtemp:AVERAGE: Avg\\: %4.1lf",
	      "GPRINT:livingroomtemp:LAST: Current\\: %4.1lf  [degrees C]\\n";
    
  if ($ERROR = RRDs::error) {
    print "$0: unable to generate $_[0] graph: $ERROR\n";
  }
}

# location of rrdtool databases
my $rrd = $ENV{'RRDLOGGER_DATA'};   # was '/var/rrd';
# location where the images should go
my $img = $ENV{'RRDLOGGER_LOGDIR'}; # was '/home/ana/Tools/rrd';

# logfile for temperatures
my $logFile = "$ENV{'RRDLOGGER_LOGDIR'}/temperatures.log"; # was "/home/ana/log/temperatures.log";
system("touch $logFile");

# get temp for inside and outdoor sensors
#printf " Office: /usr/local/bin/temperature\n";
my $tempOffice  = `/usr/local/bin/temperature`;
chop($tempOffice);

#printf " Living Room: ssh root\@pausmovi /usr/local/bin/temperature\n";
my $tempLivingRoom  = `ssh root\@pausmovi /usr/local/bin/temperature`;
chop($tempLivingRoom);

my $cmd = "wget -O temperature-ArlingtonHeightTurkeyHill.tmp ";
$cmd   .= "http://www.wunderground.com/weatherstation/WXDailyHistory.asp";
$cmd   .= "\\?ID=KMAARLIN3\\&format=1 2> /dev/null";
#printf " Turkey Hill: $cmd\n";
my $rc = system($cmd);
if ($rc != 0) {
  printf " ERROR - could not grab data from Arlington Height (Turkey hgill) Station.";
  exit 0;
}

$cmd  = "grep -v \\<br\\> temperature-ArlingtonHeightTurkeyHill.tmp";
$cmd .= " | grep Weather | tail -1 | cut -d, -f2";
my $tempOutdoor=`$cmd`;

# get last outdoor reading
my $lastTempOutdoor=`cat $logFile | tail -1 | cut -d' ' -f3`;    
chop($lastTempOutdoor);

# alternatively use the weather tool (does not offer Turkey Hill Weather Station)
#my $tempOutdoor = `cd /home/ana/Tools/weather; ./weather --forecast --no-cache-data 02474| grep Temperature:| tr -s ' ' | cut -d' ' -f3`;

$DATE=`date`;
chop($DATE);
chop($tempOutdoor);
system("echo \"$tempOffice $tempLivingRoom $tempOutdoor $DATE\" >> $logFile");

if ("$tempOutdoor" eq " " || "$tempOutdoor" eq "0" || "$tempOutdoor" eq "") {
  # recover from temporary failure
  $tempOutdoor = $lastTempOutdoor;
  printf " ERROR - reading of external temperature must have failed .... use last one.";
  #exit;
}

# convert: Fahrenheit -> Celsius
$tempOutdoor=($tempOutdoor-32.0)*5.0/9.0;

if ($tempOffice <= 1.0) {
  printf " ERROR - reading of internal temperature must have failed ....";
  exit;
}
if ($tempOutdoor <= -50.0 || $tempOutdoor >= 50.0) {
  printf " ERROR - reading of external temperature must have failed ....";
  exit;
}

printf "\n Insert into database [C] ==== Office:%6.2f LivingRoom:%6.2f Outdoor:%6.2f ====\n\n",
    $tempOffice,$tempLivingRoom,$tempOutdoor;
	
# create database if it does not exist
if (! -e "$rrd/logger.rrd") {
  print " creating rrd database ...\n";
  RRDs::create "$rrd/logger.rrd","-s 300",
               "DS:office-temp:GAUGE:600:-20:100",
               "DS:livingroom-temp:GAUGE:600:-20:100",
               "DS:outdoor-temp:GAUGE:600:-20:100",
               "RRA:AVERAGE:0.5:1:576",
               "RRA:AVERAGE:0.5:6:672",
               "RRA:AVERAGE:0.5:24:732",
               "RRA:AVERAGE:0.5:144:1460";
}

# insert values
RRDs::update "$rrd/logger.rrd", "-t",
             "office-temp:livingroom-temp:outdoor-temp",
             "N:$tempOffice:$tempLivingRoom:$tempOutdoor";

# deal with possible errors
if ($ERROR = RRDs::error) {
  print "$0: unable to update $rrd/logger.rrd: $ERROR\n";
}

# create graphs
&CreateAllGraphs   ("day",  $rrd,$img);
&CreateAllGraphs   ("week", $rrd,$img);
&CreateAllGraphs   ("month",$rrd,$img);
&CreateAllGraphs   ("year", $rrd,$img);

&CreateInsideGraphs("day",  $rrd,$img);
&CreateInsideGraphs("week", $rrd,$img);
&CreateInsideGraphs("month",$rrd,$img);
&CreateInsideGraphs("year", $rrd,$img);

# export graphs to the web
$DATE=`date`;
chop($DATE);
$cmd  = "rm -f $ENV{'RRDLOGGER_LOGDIR'}/index.html;";
$cmd .= " sed -e \'s/XX-TIME-XX/$DATE/\' $ENV{'RRDLOGGER_DIR'}/index-template.html";
$cmd .= " > $ENV{'RRDLOGGER_LOGDIR'}/index.html";
printf "CMD: $cmd\n";
system($cmd);
$cmd = "su - ana -c \"scp -r $ENV{'RRDLOGGER_LOGDIR'} paus\@paushaus.dyndns.org:www\"";
printf "CMD: $cmd\n";
system($cmd);

exit 0;
