extensions [array csv]

globals [
  ;;annual globals
  day_num ;;day number
  year
  normal_death_threshold death_threshold ;;probability of death
  reprod_threshold ;;probablity of reproducing
  temperature ;temperature in a given day
  var ;multi-use temporary variable

  ;;daily globals
  num-turtles
  amount_egested
  consumption-in-period
  periods-in-day
  counter
  organic-regen
  steps-per-ie
  max_stamina
  min_stamina
  current_month
  next_month
  num_days
  temperatures
  day_of_month


  obstacle
  obstacle_list
  temp_arr

  temp_shape
  temp_size
  temp_x
  temp_y
  temp_pH
  temp_movable

  ]

breed [cocoons]
breed [adults]

turtles-own [
  death_p     ;probability of death and reproduction of each worm
  reprod_p
  maturation
  wait_period ;days taken by cocoon to hatch given optimal temperature considitions
  hatch_temp  ;minimum temperature required for cocoons to hatch

  stamina     ;helps simulate starvation
  time-since-eaten
  food-consumed-last
  iseating?
  cycle-counter
  ;;speed



  ]

patches-own
[
  ph        ;pH values ranging from 0-14
  food-here ;amount of food on this patch
  permeability ;; 0 - 1, 0 being completely impermeable, 1 meaning complete freedom of movement
  local_death_threshold
  food-consumed-from

]

to setup
  clear-all

  set day_num starting_day
  set year 0
  set periods-in-day 10

  set temperatures (list January February March April May June July August September October November December)
  set num_days (list 31 28 31 30 31 30 31 31 30 31 30 31)
  set current_month 0
  set var starting_day
  while [var > 0]
  [
    if var > item current_month num_days
    [
     set current_month current_month + 1

    ]
    set var var - item current_month num_days
  ]
  calculate_temp
  set day_of_month (var + (item ((current_month - 1) mod 12) num_days))
  ;;set next_month current_month + 1 mod 12


  set normal_death_threshold 0.685 / (2 * periods-in-day) ; Simulates a 4 year life span
  set death_threshold normal_death_threshold
  set reprod_threshold normal_reproduction_rate ; Simulates successful births

  set steps-per-ie 5
  set max_stamina (2 * steps-per-ie)
  set min_stamina 1

  set counter 0
  set num-turtles 40
  set amount_egested 1
  set consumption-in-period 1

  set organic-regen 0.3 ;;0.004;; / 5
  set temp_arr array:from-list n-values 6 [0] ;array used to temporarily store obstacle parameters
  set obstacle array:to-list temp_arr

  ;print obstacle
  set obstacle_list n-values number_of_obstacles [obstacle]
  show obstacle_list

  ask patches
  [
    set permeability 1
    set ph 7
    set local_death_threshold death_threshold

    setup-initial-food
    ;foreach obstacle_list [setup-obstacles ? ]
    recolor-patch
  ]
 create-adults worm_population[
    move-to one-of patches with [permeability > 0]
    set size 1
    set shape "worm"

    set maturation 70
    set wait_period 40
    set hatch_temp 15
    set stamina 6
    set food-consumed-last 0
    set iseating? one-of[true false]
    set cycle-counter (random (steps-per-ie + 1))
    ;;set speed 0.3;; / 5

   ]
 reset-ticks
end


to add_obstacle
  array:set temp_arr 0 obstacle_shape
  array:set temp_arr 1 obstacle_size
  array:set temp_arr 2 obstacle_x
  array:set temp_arr 3 obstacle_y
  array:set temp_arr 4 obstacle_pH
  array:set temp_arr 5 movement

  set obstacle array:to-list temp_arr
  set obstacle_list replace-item (obstacle_number - 1) obstacle_list obstacle
  show obstacle_list

  ;foreach obstacle_list [show ?]

 draw_obstacles

end

to draw_obstacles
    ask patches [
    foreach obstacle_list [setup-obstacles ? ]

    recolor-patch
    ]

end

to save
  print "Saved: "

  let filename (word "myobstacle"  save_number ".csv")
  csv:to-file filename obstacle_list
  show obstacle_list
end

to load
  let filename (word "myobstacle"  save_number ".csv")
  set obstacle_list csv:from-file filename
  print "Loaded: "
  show obstacle_list
  draw_obstacles

end


to setup-initial-food
;  let setup-patch one-of patches
;  if (distancexy 0 60) < 30
;  [
;    set food-here 400
;  ]
;
;  let setup-patch2 one-of patches
;  if (distancexy 0 -60) < 30
;  [
;    set food-here 400
;  ]

;set food-here (random 251 + 250)
  set food-here 500
end

to recolor-patch
  ifelse (permeability != 0)
  [
    set pcolor scale-color green food-here 600 0
    if (ph != 7) [ set pcolor scale-color violet food-here 600 0]

  ]
  [
    set pcolor blue
  ]
end


to setup-obstacles [one_obstacle]
  ;if obstacle parameters given

  if (item 0 one_obstacle != 0) [
    ;looks at items in the array to setup the obstacle

    set temp_shape item 0 one_obstacle
    set temp_size item 1 one_obstacle
    set temp_x item 2 one_obstacle
    set temp_y item 3 one_obstacle
    set temp_pH item 4 one_obstacle
    set temp_movable item 5 one_obstacle


    if temp_shape = "circle"
    [
      if (distancexy temp_x temp_y) < temp_size [
        ifelse temp_movable [
         set permeability 1
         ]
        [ set food-here 0
          set permeability 0
          ask turtles-here [die]
          ]
        set ph random-normal temp_pH 1

      ]
    ]
    if temp_shape = "square"
    [
      if pxcor >= temp_x - temp_size and pxcor <= temp_x + temp_size and pycor >= temp_y - temp_size and pycor <= temp_y + temp_size
      [
        ifelse temp_movable [
         set permeability 1
         ]
        [ set food-here 0
          set permeability 0
          ask turtles-here [die]
          ]
        set ph random-normal temp_pH 1

      ]
    ]

    if temp_shape = "horizontal-line"
    [
      if distancexy temp_x temp_y <= temp_size and temp_y = pycor
      [
        ifelse temp_movable [
          set permeability 1
        ]
        [ set food-here 0
          set permeability 0
          ask turtles-here [die]
        ]
        set ph random-normal temp_pH 1
      ]

    ]
    if temp_shape = "vertical-line"
    [
      if distancexy temp_x temp_y <= temp_size and temp_x = pxcor
      [
        ifelse temp_movable [
          set permeability 1
        ]
        [ set food-here 0
          set permeability 0
          ask turtles-here [die]
        ]
        set ph random-normal temp_pH 1 ]
    ]
  ]
end


to move
  set stamina stamina - 0.3
  let potential-destinations (patch-set patch-here neighbors with [permeability != 0])
  ifelse iseating?
  [
    ;; uphill [food-here]
    ;;face max-one-of potential-destinations [food-here]
    right (random 181) - 90
    forward speed * permeability
    eat

    if cycle-counter >= steps-per-ie
    [
      set iseating? false
      set cycle-counter 0
    ]
  ]
  [
    ;; downhill [food-here]
    ;;face max-one-of potential-destinations [food-consumed-from]
    ;;face min-one-of potential-destinations [food-here]
    right (random 181) - 90
    forward speed * permeability
    egest
    if cycle-counter >= steps-per-ie
    [
      set iseating? true
      set cycle-counter 0
    ]
  ]
  check_death
  if not iseating? [check_reproduction]
  set cycle-counter cycle-counter + 1
end


to eat

  ifelse (food-here < consumption-in-period) ;;prevents consuming more food than on patch
  [
    set food-consumed-last food-here
    set food-here 0
  ]
  [
    set food-consumed-last consumption-in-period
    set food-here food-here - consumption-in-period
    set time-since-eaten 0
  ]

  if (food-here > 0) [
      if (stamina < max_stamina) [set stamina stamina + food-consumed-last]
    ]

  set food-consumed-from food-consumed-from + consumption-in-period
  ;;ifelse (stamina < (max_stamina - food-consumed-last)) [ set stamina stamina + food-consumed-last ]
  ;;[if stamina < max_stamina [set stamina max_stamina]]

  ;if (stamina < max_stamina) [set stamina stamina + 1]

  ;;if time-since-eaten > 40
  ;;[die]

end


to egest
  set food-consumed-from food-consumed-from - ((1 - amount_egested) * food-consumed-last / steps-per-ie)
  ;;set food-here food-here + ((1 - amount_egested) * food-consumed-last)
  set food-consumed-last food-consumed-last / steps-per-ie
end


;to-report food-count
;  let food-total 0
;  ask patches
;  [
;    set food-total food-total + food-here
;  ]
;  report food-total
;end



to check_death
  random-seed new-seed
  set death_p random-float 100
  set local_death_threshold death_threshold

  ;;pH of soil also affects survival rate
  if (ph < 5) [
    ;show ph
    set var 6 - ph
    set var abs var
;   set local_death_threshold (death_threshold + (max_death_rate / 7 * var))
    set local_death_threshold (death_threshold + (random 55) / 5 * var ) ;55% chance of them dying at lowest pH
  ]

  ifelse (stamina < min_stamina) [die] ;; dies if out of energy
  [if (death_p < local_death_threshold) [die]] ;; dies of cold/natural causes

  end

to check_reproduction
  ;;random-seed new-seed
  set reprod_p random-float 100
  if (reprod_p < reprod_threshold) [
    if (maturation = 70) [
      hatch-cocoons 3 [
        set maturation 0
        set color white
        set shape "dot"
        ]
      ;set maturation maturation - 10 ;;wait a few days before laying next cocoon
      ]
  ]
end

;updates probablities of dying and reproducing
to update_thresholds
  ;cold reduces survival rate
  ifelse (temperature < 6) [
    set death_threshold max_death_rate
    ]
  [
    ifelse (temperature > 25)[set death_threshold max_death_rate]
      [set death_threshold (normal_death_threshold / temperature)]
   ] ; probability of dying decreases as it gets warmer

  ;reproduction rate affected by temperature
  if (temperature > 10) [
    set reprod_threshold (max_reproduction_rate / (10 * 2 * periods-in-day) * temperature) ] ; probability of reproducing increases as it gets warmer (10 * 2 * periods-in-day)

end

to update_maturity
    if (maturation < 70) [
      set maturation maturation + 1
    ]
end

;;hatches temperature is optimum for birth
to check_if_hatch
    ifelse (temperature > hatch_temp) [
      set wait_period wait_period - 1

      if (wait_period < 1) [
      set breed adults
      set size 1
      set shape "worm"]
    ] [if (wait_period > 37) [set wait_period 40] ] ;to minimize affect by random fluctuations
end


to calculate_time
  ;; two ticks to simulate one gestation cycle
  ;; worm completes 10 cycles in one day
  if (ticks mod (2 * periods-in-day) = 0) [
    set day_num day_num + 1
    ]
  if (day_num = 366) [
    set year year + 1
    set day_num day_num mod 365 ;;reset for every year
  ]
  end

;Calcualtes temperature for every day based on Bhaskar I's sine approxiamtion formula
;Roughly simulates a temperature curve
to calculate_temp
  set day_of_month day_of_month + 1
    if day_of_month > item current_month num_days
    [
      set current_month (current_month + 1) mod 12
      set day_of_month 0
    ]
    set temperature random-normal (item current_month temperatures) (2)
;    set temperature (4 * var * (180 - var)) / (40500 - var * (180 - var))
;    set temperature temperature * max_temperature ;scales temperature to real world values

end


to update_organic_matter
end

to go
  calculate_time

  ;show temperature
  if (year = 10) [stop]
  if (count turtles = 0) [stop]

  if (ticks mod (2 * periods-in-day) = 0) [
    update_thresholds
    calculate_temp
    update_organic_matter

    ask cocoons [
      check_if_hatch
      ;;show wait_period
    ]
  ]

  ask adults [
    ;update_speed
    if (ticks mod (2 * periods-in-day) = 0) [
      update_maturity
      ;show maturation
      ]
    move
    recolor-patch
    set food-here food-here + organic-regen
  ]

  ;;foreach obstacle show
  ;;ask patches [recolor-patch]
  ;;ask patches [set food-here food-here + organic-regen]
  ;;show food-count


  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
267
10
1085
849
50
50
8.0
1
10
1
1
1
0
0
0
1
-50
50
-50
50
1
1
1
ticks
60.0

BUTTON
11
383
77
416
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
94
383
153
417
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1100
50
1208
95
Day Number
day_num
17
1
11

SLIDER
9
86
229
119
worm_population
worm_population
0
500
500
10
1
NIL
HORIZONTAL

PLOT
1099
156
1358
325
Worm Population for Current Year
Day Number
Population
0.0
365.0
0.0
1000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plotxy day_num count turtles\nif (day_num = 365) [clear-plot]"

SLIDER
8
133
228
166
normal_reproduction_rate
normal_reproduction_rate
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
8
172
230
205
max_reproduction_rate
max_reproduction_rate
0
10
7.7
0.1
1
NIL
HORIZONTAL

SLIDER
8
212
230
245
max_death_rate
max_death_rate
0
100
30
1
1
NIL
HORIZONTAL

MONITOR
1101
101
1208
146
Population Count
count adults
17
1
11

PLOT
1095
334
1359
507
Worm Population over Years
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -11221820 true "" "plotxy year count turtles"

PLOT
1094
510
1361
685
Organic Material Over Time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plotxy ticks / (periods-in-day * 2 * steps-per-ie) (sum [food-here] of patches)"

MONITOR
1216
101
1314
146
Cocoon Count
count cocoons
17
1
11

INPUTBOX
9
10
88
70
starting_day
190
1
0
Number

MONITOR
1216
51
1311
96
Daily Temp *C
temperature
2
1
11

CHOOSER
7
473
148
518
obstacle_shape
obstacle_shape
"circle" "square" "horizontal-line" "vertical-line"
2

SLIDER
5
525
177
558
obstacle_size
obstacle_size
0
50
20
1
1
NIL
HORIZONTAL

SLIDER
5
566
177
599
obstacle_x
obstacle_x
-50
50
-25
1
1
NIL
HORIZONTAL

SLIDER
5
605
177
638
obstacle_y
obstacle_y
-50
50
-19
1
1
HORIZONTAL
HORIZONTAL

SLIDER
5
605
177
638
obstacle_y
obstacle_y
-50
50
-19
1
1
NIL
HORIZONTAL

INPUTBOX
95
11
214
71
max_temperature
20
1
0
Number

SLIDER
8
649
180
682
obstacle_pH
obstacle_pH
0
14
5.5
0.1
1
NIL
HORIZONTAL

SLIDER
9
258
181
291
speed
speed
0
1
0.1
0.1
1
NIL
HORIZONTAL

INPUTBOX
3
310
124
372
number_of_obstacles
4
1
0
Number

CHOOSER
155
472
260
517
obstacle_number
obstacle_number
1 2 3 4 5 6 7 8 9 10
0

BUTTON
8
731
71
764
Add
add_obstacle
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
8
690
118
723
movement
movement
0
1
-1000

SLIDER
1093
690
1126
840
January
January
-20
40
-5
1
1
NIL
VERTICAL

SLIDER
1134
690
1167
840
February
February
-20
40
-4
1
1
NIL
VERTICAL

SLIDER
1176
691
1209
841
March
March
-20
40
1
1
1
NIL
VERTICAL

SLIDER
1219
691
1252
841
April
April
-20
40
7
1
1
NIL
VERTICAL

SLIDER
1260
691
1293
841
May
May
-20
40
13
1
1
NIL
VERTICAL

SLIDER
1300
692
1333
842
June
June
-20
40
18
1
1
NIL
VERTICAL

SLIDER
1341
692
1374
842
July
July
-20
40
21
1
1
NIL
VERTICAL

SLIDER
1382
693
1415
843
August
August
-20
40
20
1
1
NIL
VERTICAL

SLIDER
1422
694
1455
844
September
September
-20
40
15
1
1
NIL
VERTICAL

SLIDER
1463
693
1496
843
October
October
-20
40
9
1
1
NIL
VERTICAL

SLIDER
1505
693
1538
843
November
November
-20
40
4
1
1
NIL
VERTICAL

SLIDER
1546
693
1579
843
December
December
-20
40
-2
1
1
NIL
VERTICAL

BUTTON
8
431
95
464
NIL
save
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
104
431
189
464
NIL
load
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
173
360
256
420
save_number
2
1
0
Number

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

worm
true
0
Polygon -2674135 true false 150 210 150 225 120 255 90 270 75 270 60 255 60 240 90 225 105 195 135 180 165 135 150 105 135 75 135 60 120 60 105 45 105 30 120 15 135 15 165 30 165 45 180 45 195 75 210 105 210 135 210 150 195 165 180 195 165 210

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
