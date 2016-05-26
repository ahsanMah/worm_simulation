extensions [array csv]
__includes["environment.nls" "agents.nls"]

to setup
  clear-all

  setup_environment
  setup_agents

 reset-ticks
end

to save_obstacles
  let filename (word "/data/parameters/myobstacle"  save_number ".csv")
  csv:to-file filename obstacle_list
  print "Saved to file"
end

to load_obstacles
  let filename (word "myobstacle"  save_number ".csv")
  set obstacle_list csv:from-file filename
  print "Loaded from file: "
  print obstacle_list
  draw_obstacles
end

to save_patches
  let filename (word "mypatches" save_number ".csv")
  let i min-pxcor
  let j min-pycor
  carefully [file-delete filename] []
  file-open filename
  while [(i <= max-pxcor)]
  [
   while [(j <= max-pycor)]
   [
     ask patch i j
     [
       let info (list i j ph food-here permeability local_death_threshold)
       file-open filename
       file-print csv:to-row info
       file-close
       set j j + 1
     ]
   ]
   set j min-pycor
   set i i + 1
  ]

end

to load_patches
  let filename (word "mypatches" save_number ".csv")
  let data csv:from-file filename
  foreach (data)
  [
    ask patch (item 0 ?) (item 1 ?)
    [
      set ph item 2 ?
      set food-here item 3 ?
      ;;set permeability item 4 ?
      set local_death_threshold item 5 ?
    ]
  ]
  recolor_patches
end

to save_agents
  let filename (word "data/parameters/myagents"  save_number ".csv")
  csv:to-file filename species_list
  print "Saved to file"
end

to load_agents
  let filename (word "data/parameters/myagents"  save_number ".csv")
  set species_list csv:from-file filename
  print "Loaded from file: "
  print species_list
  foreach species_list [create_species ?]
end

to save_data
  let filename (word "data/output/simulation"  save_number ".csv")
  csv:to-file filename species_list
  print "Saved to file"
end

to go

  calculate_time
  if (year = 10) [stop]
  if (count turtles = 0) [stop]

  if (ticks mod (2 * periods-in-day) = 0) [
    calculate_temp
    update_organic_matter

    ask cocoons [
      check_if_hatch
    ]
  ]

  ask adults [
    ;update_speed
    if (ticks mod (2 * periods-in-day) = 0) [
      update_maturity
      update_thresholds
      ;show maturation
      ]
    move

    set food-here food-here + organic-regen
  ]
  ask patches
  [
   recolor-patch
  ]

  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
268
10
1118
881
-1
-1
7.0
1
10
1
1
1
0
0
0
1
0
119
0
119
1
1
1
ticks
1000.0

BUTTON
12
10
78
43
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
95
10
154
44
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
1148
54
1256
99
Day Number
day_num
17
1
11

SLIDER
9
152
208
185
worm_population
worm_population
0
500
160
10
1
NIL
HORIZONTAL

PLOT
1147
158
1406
327
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
"default" 1.0 0 -16777216 true "" "plotxy day_num count adults\nif (day_num = 365) [clear-plot]"
"pen-1" 1.0 0 -2674135 true "" "plotxy day_num (array:item population_arr 0)\nif (day_num = 365) [clear-plot]"
"pen-2" 1.0 0 -11221820 true "" "plotxy day_num (array:item population_arr 1)\nif (day_num = 365) [clear-plot]"
"pen-3" 1.0 0 -2064490 true "" "plotxy day_num (array:item population_arr 2)\nif (day_num = 365) [clear-plot]"
"pen-4" 1.0 0 -955883 true "" "plotxy day_num (array:item population_arr 3)\nif (day_num = 365) [clear-plot]"
"pen-5" 1.0 0 -5825686 true "" "plotxy day_num (array:item population_arr 4)\nif (day_num = 365) [clear-plot]"

SLIDER
8
194
209
227
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
233
208
266
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
273
207
306
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
1149
103
1256
148
Population Count
count adults
17
1
11

PLOT
1143
336
1407
509
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
"default" 1.0 1 -11221820 true "" "plotxy year count adults"

PLOT
1142
512
1409
687
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
1264
103
1362
148
Cocoon Count
count cocoons
17
1
11

INPUTBOX
8
57
87
117
starting_day
190
1
0
Number

MONITOR
1264
53
1359
98
Daily Temp *C
temperature
2
1
11

CHOOSER
9
656
150
701
obstacle_shape
obstacle_shape
"circle" "square" "horizontal-line" "vertical-line"
1

SLIDER
7
708
179
741
obstacle_size
obstacle_size
0
50
19
1
1
NIL
HORIZONTAL

SLIDER
7
749
179
782
obstacle_x
obstacle_x
min-pxcor
max-pxcor
77
1
1
NIL
HORIZONTAL

SLIDER
7
788
179
821
obstacle_y
obstacle_y
-50
50
98
1
1
HORIZONTAL
HORIZONTAL

SLIDER
7
788
179
821
obstacle_y
obstacle_y
min-pycor
max-pycor
98
1
1
NIL
HORIZONTAL

INPUTBOX
94
58
213
118
max_temperature
20
1
0
Number

SLIDER
8
352
207
385
speed
speed
0
0.5
0.12
0.01
1
NIL
HORIZONTAL

CHOOSER
157
655
262
700
obstacle_number
obstacle_number
1 2 3 4 5 6 7 8 9 10
1

BUTTON
7
826
70
859
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

SLIDER
1146
692
1179
842
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
1187
692
1220
842
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
1226
692
1259
842
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
1267
693
1300
843
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
1308
693
1341
843
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
1348
694
1381
844
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
1389
694
1422
844
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
1430
695
1463
845
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
1470
696
1503
846
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
1511
695
1544
845
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
1553
695
1586
845
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
1594
695
1627
845
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
574
133
607
Save Obstacles
save_obstacles
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
136
574
262
607
Load Obstacles
load_obstacles
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
11
509
94
569
save_number
4
1
0
Number

SLIDER
1420
54
1592
87
patch_width
patch_width
4
12
6
2
1
NIL
HORIZONTAL

SLIDER
1419
94
1591
127
patch_height
patch_height
4
12
6
2
1
NIL
HORIZONTAL

SLIDER
1420
163
1592
196
patch_x
patch_x
1
patch_width
3
1
1
NIL
HORIZONTAL

SLIDER
1421
202
1593
235
patch_y
patch_y
1
patch_height
4
1
1
NIL
HORIZONTAL

SLIDER
1420
241
1592
274
patch_pH
patch_pH
0
14
3.1
0.1
1
NIL
HORIZONTAL

BUTTON
1419
323
1515
356
NIL
add_patch
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
1606
238
1738
271
change-pH?
change-pH?
0
1
-1000

CHOOSER
1423
370
1561
415
Show:
Show:
"pH" "food" "temperature"
1

TEXTBOX
10
129
120
147
Species Control
13
0.0
1

SLIDER
9
311
205
344
species_genetic_diversity
species_genetic_diversity
0
1
0.6
0.1
1
NIL
HORIZONTAL

SLIDER
8
389
207
422
species_hatch_temperature
species_hatch_temperature
0
25
11
1
1
NIL
HORIZONTAL

CHOOSER
10
459
110
504
species_number
species_number
1 2 3 4 5
2

BUTTON
128
467
191
500
Add
add_species
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
1526
323
1658
356
NIL
recolor_patches
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
8
612
131
645
Save Patches
save_patches
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
135
613
260
646
Load Patches
load_patches
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
9
423
101
456
start_x
start_x
0
119
46
1
1
NIL
HORIZONTAL

SLIDER
115
424
207
457
start_y
start_y
0
119
97
1
1
NIL
HORIZONTAL

BUTTON
130
505
193
538
Save
save_agents
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
196
505
259
538
Load
load_agents
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

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

cyan_worm
true
0
Polygon -11221820 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

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

magenta_worm
true
0
Polygon -5825686 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

orange_worm
true
0
Polygon -955883 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

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

pink_worm
true
0
Polygon -2064490 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

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

red_worm
true
0
Polygon -2674135 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

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

violet_worm
true
0
Polygon -8630108 true false 165 240 135 255 105 270 90 270 75 255 75 240 105 225 120 195 150 180 180 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 75 225 105 225 135 225 150 210 165 195 195 180 210
Line -16777216 false 150 60 180 45
Line -16777216 false 150 75 195 45
Line -16777216 false 150 60 150 75
Line -16777216 false 195 45 180 45

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
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>year</metric>
    <enumeratedValueSet variable="starting_day">
      <value value="190"/>
      <value value="100"/>
      <value value="250"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
