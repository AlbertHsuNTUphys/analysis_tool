####################################################################
# :Usage                                                           #  
#  - deal all the procedure needed to submit Impact fit to condor. #
# :Command                                                         #
#  - sh plot_Impact.sh 2018 mm 350 rtc04 s_plus_b interference     #
# :Input parameter(order is important)                             #
#  - 1: era [2016apv/2016postapv/2017/2018/run2]                   #
#  - 2: channel [ee/em/mm/C]                                       #
#  - 3: mass                                                       #
#  - 4: coupling [rtc04/rtu04]                                     #
#  - 5: expectSignal [s_plus_b/b_only]                             #
#  - 6: interference [interference/pure]                           #
####################################################################

cmsenv

RED='\033[0;31m'
NC='\033[0m'
UBlue='\033[4;34m'        # Blue
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White


startpoint=20
loop=true
era=$1
channel=$2
mass=$3
coupling=$4

expectSignal=""
expectSignal_tag="b_only"
if [[ $5 == "s_plus_b" ]]; then
  expectSignal="--expectSignal"
  expectSignal_tag=$5
fi
interference=""
if [[ $6 == "interference" ]]; then
  interference="--interference"
fi
##########################
##  datacard2workspace  ##
##########################

python ./SignalExtraction_Estimation.py -y $era -c $channel --mode datacard2workspace --coupling_value $coupling --mass_point $mass $expectSignal $interference

#####################
## FitDiagnostics  ##
#####################

rmax=20
rmin=-20

while $loop
do
  rmax=$startpoint
  rmin=$((startpoint*-1))

  echo -e "${BCyan}fit with rmin ${rmin} and rmax ${rmax}${NC}"

  python ./SignalExtraction_Estimation.py -y $era -c $channel --mode FitDiagnostics --coupling_value $coupling --mass_point $mass --rMin $rmin --rMax $rmax $expectSignal $interference

  if [[ $6 == "interference" ]]; then
    massS=$(($mass-50))
    Line=$(grep -n "Best" SignalExtraction/$era/$channel/$coupling/A_interfered_with_S0/$mass/$expectSignal_tag/ttc_$coupling\_datacard_$era\_SR_$channel\_$channel\_MA$mass\_MS$massS\_FitDiagnostics.log)
  else
    Line=$(grep -n "Best" SignalExtraction/$era/$channel/$coupling/A/$mass/$expectSignal_tag/ttc_$coupling\_datacard_$era\_SR_$channel\_$channel\_MA$mass\_FitDiagnostics.log)
  fi
  echo $Line
  Line=$(echo $Line | grep -Eo '[-][0-9]+([.][0-9]+)?[/][+][0-9]+([.][0-9]+)?')

  echo $Line

  UpperBound=$(echo $Line | grep -Eo '[+][0-9]+([.][0-9]+)?'  | cut -f2 -d"+" )
  LowerBound=$(echo $Line | grep -Eo '[-][0-9]+([.][0-9]+)?')

  UpperPass="$(echo "${UpperBound} < ${rmax}" | bc)"
  LowerPass="$(echo "${LowerBound} > ${rmin}" | bc)"

  if [ 1 -eq $UpperPass ] | [ 1 -eq $LowerPass ]; then
    loop=false
  else
    startpoint=$(($startpoint+5))
  fi
  echo -e "${BCyan}UpperBound: ${UpperBound}, LowerBound: ${LowerBound}${NC}"
done

#####################
## preFitPlot etc. ##
#####################
python ./SignalExtraction_Estimation.py -y $era -c $channel --mode preFitPlot --coupling_value $coupling --mass_point $mass $expectSignal $interference --rMin $rmin --rMax $rmax
python ./SignalExtraction_Estimation.py -y $era -c $channel --mode postFitPlot --coupling_value $coupling --mass_point $mass $expectSignal $interference --rMin $rmin --rMax $rmax
python ./SignalExtraction_Estimation.py -y $era -c $channel --mode diffNuisances --coupling_value $coupling --mass_point $mass $expectSignal $interference --rMin $rmin --rMax $rmax
python ./SignalExtraction_Estimation.py -y $era -c $channel --mode PlotPulls --coupling_value $coupling --mass_point $mass $expectSignal $interference --rMin $rmin --rMax $rmax
python ./SignalExtraction_Estimation.py -y $era -c $channel --mode Impact_doInitFit --coupling_value $coupling --mass_point $mass $expectSignal $interference --rMin $rmin --rMax $rmax
python ./SignalExtraction_Estimation.py -y $era -c $channel --mode Impact_doFits --coupling_value $coupling --mass_point $mass $expectSignal $interference --rMin $rmin --rMax $rmax
