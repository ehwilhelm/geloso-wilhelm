use "C:\Users\C00535185\Dropbox\Papers\When a Country Becomes More Economically Free - Who Benefits - Anybody Lose\Data\MergeReady\ALLDATA.dta" , clear


*Table #5 -- Income Decile Growth -- 5yr



*share10
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_10  ///
, outcome(change_inc_10_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9 ///
, outcome(change_inc_9_5yr) n(3) common logit ate caliper(0.05)

	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_10  ///
, outcome(change_inc_10_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_10 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_10 ///
, outcome(change_inc_10_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_10_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_10) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_10)


tebalance summarize 



*share9

psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9  ///
, outcome(change_inc_9_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9 ///
, outcome(change_inc_9_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9  ///
, outcome(change_inc_9_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9 ///
, outcome(change_inc_9_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_9_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_9)








*share8

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_8  ///
, outcome(change_inc_8_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_8 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_8 ///
, outcome(change_inc_8_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_8  ///
, outcome(change_inc_8_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_8 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_8 ///
, outcome(change_inc_8_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_8_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_8) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_8)









*share7

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_7  ///
, outcome(change_inc_7_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_7 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_7 ///
, outcome(change_inc_7_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_7  ///
, outcome(change_inc_7_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_7 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_7 ///
, outcome(change_inc_7_5yr) kernel common logit ate caliper(0.05)


	*MAHNN3
teffects nnmatch (change_inc_7_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_7) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_7)






*share6

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_6  ///
, outcome(change_inc_6_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_6 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_6 ///
, outcome(change_inc_6_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_6  ///
, outcome(change_inc_6_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_6 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_6 ///
, outcome(change_inc_6_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_6_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_6) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_6)





*share5

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_5  ///
, outcome(change_inc_5_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_5 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_5 ///
, outcome(change_inc_5_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_5  ///
, outcome(change_inc_5_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_5 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_5 ///
, outcome(change_inc_5_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_5_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_5) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_5)







*share4

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_4  ///
, outcome(change_inc_4_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_4 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_4 ///
, outcome(change_inc_4_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_4  ///
, outcome(change_inc_4_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_4 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_4 ///
, outcome(change_inc_4_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_4_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_4) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_4)








*share3

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_3  ///
, outcome(change_inc_3_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_3 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_3 ///
, outcome(change_inc_3_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_3  ///
, outcome(change_inc_3_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_3 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_3 ///
, outcome(change_inc_3_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_3_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_3) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_3)









*share2

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_2  ///
, outcome(change_inc_2_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_2 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_2 ///
, outcome(change_inc_2_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_2  ///
, outcome(change_inc_2_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_2 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_2 ///
, outcome(change_inc_2_5yr) kernel common logit ate caliper(0.05)


	*MAHNN3
teffects nnmatch (change_inc_2_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_2) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_2)





*share1

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_1  ///
, outcome(change_inc_1_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_1 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_1 ///
, outcome(change_inc_1_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_1  ///
, outcome(change_inc_1_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_1 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_1 ///
, outcome(change_inc_1_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_1_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_1) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_1)






*top5

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top5  ///
, outcome(change_inc_top5_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top5 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top5 ///
, outcome(change_inc_top5_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top5  ///
, outcome(change_inc_top5_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top5 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top5 ///
, outcome(change_inc_top5_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_top5_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top5) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top5)






*top1

	*NN3
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top11  ///
, outcome(change_inc_top1_5yr) n(3) common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top11 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top11 ///
, outcome(change_inc_top1_5yr) n(3) common logit ate caliper(0.05)


	*Kernel
psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top11  ///
, outcome(change_inc_top1_5yr) kernel common logit ate caliper(0.05)
pstest lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top11 , both 
set seed 12345
bootstrap r(att), r(200): psmatch2 EFWjump lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top11 ///
, outcome(change_inc_top1_5yr) kernel common logit ate caliper(0.05)

	*MAHNN3
teffects nnmatch (change_inc_top1_5yr lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top11) ///
(EFWjump), nn(3) atet biasadj(lagEFW laghc laglngdppc laggdpc_5growth laglngdppc2 lagfertilrate lagoldagedep lagpolity2 lagurbanpop lag_inc_top11)



