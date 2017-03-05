globals [
  loop-counter
  roads
  lane-ycord
  lane-fast-id
  lane-medium-id
  lane-slow-id
  max-speed-limit
  min-speed-limit
  lead-car
  lead-car-moves
  prev-xcor
  prev-ycor
  car-ahead
	lane-fast-ypos
  lane-medium-ypos
	lane-slow-ypos
  debug
  conflicts
]

extensions [table]

breed [ dividers divider ]
breed [ cars car ]
breed [ lanes lanee ] 


cars-own [
  speed
  previous-x
  agressive?
  
  
    ; basic properties of the car
  
  current-speed ; what is my current speed
  preferred-speed ; what is my preferred speed ( 1 lowest -> 10 highest )
  current-lane-id ; what lane ID am i in
  cooperativeness-rating ; how willing am i to let someone in my lane? ( 1 lowest -> 10 highest )
  next-lane-id ; what is his next choice?
  next-speed; 
  
  ;        conditions of the adjacent lanes
  
  ; are the lanes above and below even feasible?
  laneBelowFeasible
  laneAboveFeasible
  
  ; evaluations of my speed (must be updated each time a drive)
  abovePreferredSpeed
  belowPreferredSpeed
  
  ; based on my preferred speed, what lanes do i want?
  wantFasterLane
  wantSlowerLane
  
  ;        adjacent vehicles available through - getCarAbove/Below/Ahead
  
  ; 				alternatives - what are my possible choices?
  myPossibleAlternatives ; [ matchSpeedOfApproachingCar moveUpLane moveDownLane speedUp slowDown staySameSpeed ]
  
]

lanes-own [
  
  ; attributes
	current-congestion ; // how full are we?
  max-speed ; max
  min-speed ; min
  emission-rating ; cars traveling in this lane emit this for their emissions
  y-pos ; where are we on the y axis
]

;*********************** Lanes *********************************

  ; methods

  to update-lane ; lane procedure
    ; update all of lane parameters here
    let congestion 0
    let laneY y-pos
    ; find all cars on this y coordinate
      ask cars [
        if (pycor = laneY)
        [ set congestion congestion + 1 ]
      ]
    set current-congestion congestion    
    
  end
    
    
    ; ******* group of lanes ********
    
    
    to update-lanes
      ask lanes [
        update-lane
      ]
    end
    
      
      
    to setup-lanes
      let line (max-pycor * 2 / 3)
      
      set lane-slow-ypos (min-pycor + (line / 2))
      set lane-medium-ypos 0
      set lane-fast-ypos (max-pycor - (line / 2))
      
			create-lanes 3 [
        set current-congestion 0
      ] ; create 3 lanes 
      
      ; update each based on their number
      
      set lane-fast-id 4
      set lane-medium-id 3
      set lane-slow-id 2
      
      ask lanee lane-fast-id [ 
        set max-speed 10
        set min-speed 7
        set emission-rating 3
        set y-pos lane-fast-ypos
      ] ; fast-lane

      ask lanee lane-medium-id [ 
        set max-speed 6
        set min-speed 4
        set emission-rating 2
        set y-pos lane-medium-ypos
      ] ; medium-lane
      
      ask lanee lane-slow-id [ 
        set max-speed 3
        set min-speed 1
        set emission-rating 1
        set y-pos lane-slow-ypos
      ] ; slow-lane
      
    end
    
    
    ;*********************** End Lanes *********************************

;*********************** Cars *********************************
     
      ; methods  
      
      to formulateAlternatives ; car procedure
        
        ; this is where the magic happens
        determineAlternatives
        
      end
      
        to determineAlternatives ; car procedure 
          set myPossibleAlternatives [ false false false false false false ] ; [ matchSpeedOfApproachingCar moveUpLane moveDownLane speedUp slowDown staySameSpeed ]
          ; change to table in future?
          
          ; can we move up a lane?
          
          let carAbove getCarAbove
          
          if(laneAboveFeasible and (carAbove = nobody) ) [
           set myPossibleAlternatives replace-item 1 myPossibleAlternatives true ; move up
          ]
          
          ; can we move up a lane?
          
          let carBelow getCarBelow
          
          if(laneBelowFeasible and (carBelow = nobody) ) [
            set myPossibleAlternatives replace-item 2 myPossibleAlternatives true ; move down
          ]

          ; can we speed up?
          
          let carAhead getCarAhead
          
          ifelse( (carAhead = nobody) ) [
            set myPossibleAlternatives replace-item 3 myPossibleAlternatives true ; speed up
            set myPossibleAlternatives replace-item 4 myPossibleAlternatives true ; slow down
            set myPossibleAlternatives replace-item 5 myPossibleAlternatives true ; stay same speed
          ] [
            set myPossibleAlternatives replace-item 0 myPossibleAlternatives true ; match upcoming cars speed
          ]
        end
          
          
      to evaluateConditions ; car procedure
        evaluateLaneConditions ; gives me info about what lanes i want and what is possible
      end

          to-report getCarAhead
            let carVar nobody

            ask cars-on patch-ahead 1 [
             set carVar self 
            ]
            report carVar
          end
            
          to-report getCarAbove ; car procedure
            let carVar nobody
            let y 0
            
            if(laneAboveFeasible) [
              ask lanee (current-lane-id + 1) [
              	set y y-pos 
            	]
              
              if( any? cars-on patch xcor y ) [                
                ask cars-on patch xcor y [
                  set carVar self 
                ]
               	
              ]
              
            ]
            report carVar            
          end
            
          to-report getCarBelow; car procedure
            let carVar nobody
            let y 0
            
            if(laneBelowFeasible) [
              ask lanee (current-lane-id - 1) [
              	set y y-pos 
            	]
              
              if( any? cars-on patch xcor y ) [                
                ask cars-on patch xcor y [
                  set carVar self 
                ]
               	
              ]
              
            ]
            report carVar            
          end     
            
          to displayCarStatus
            show "laneId (4-fast.3-med,2-slow)"
            show current-lane-id
            show "laneBelowFeasible:" 
            show laneBelowFeasible
            show "laneAboveFeasible:" 
            show laneAboveFeasible
            show "currentSpeed:"
            show current-speed
            show "preferredSpeed:"
            show preferred-speed
            show "abovePreferredSpeed:" 
            show abovePreferredSpeed
            show "belowPreferredSpeed:" 
            show belowPreferredSpeed
            show "wantFasterLane:" 
            show wantFasterLane
            show "wantSlowerLane:" 
            show wantSlowerLane
          end
            
        to evaluateLaneConditions ; car procedure
                  ; i want to know :
   
        ; are the lanes above or below me feasible?
        
        ifelse ycor = lane-slow-ypos 
        [ set laneBelowFeasible false]
        [ set laneBelowFeasible true ]
        
        ifelse ycor = lane-fast-ypos 
        [ set laneAboveFeasible false]
        [ set laneAboveFeasible true ]
        
        ; am i above or below my current speed?
        
        ifelse current-speed > preferred-speed
        [ set abovePreferredSpeed true]
        [ set abovePreferredSpeed false ]
        
        ifelse current-speed < preferred-speed
        [ set belowPreferredSpeed true]
        [ set belowPreferredSpeed false ]        
        
        ; are the speeds of this lane to my liking?
        
        let myLaneMax 0
        let myLaneMin 0
        
        ask lanee current-lane-id [
          set myLaneMax max-speed
          set myLaneMin min-speed
        ]
        
        ifelse preferred-speed > myLaneMax
        [ set wantFasterLane true]
        [ set wantFasterLane false ]  
        
        ifelse (preferred-speed < myLaneMin)
        [ set wantSlowerLane true]
        [ set wantSlowerLane false ]  
        
        if debug [ 
          show "-- Car Evaluating Conditions --"
          displayCarStatus
        ] 
        end
        to executeActions 
          changeLanes
          adjustSpeed
        end
 
          to adjustSpeed  ; car procedure
            set current-speed next-speed
            fd current-speed
          end

        
 to changeLanes ; car procedure
   
   ; changing lanes
   
   	if debug [ 
        show "-- Car Changing Lanes --"
        show "From CurrentLane:" 
      show current-lane-id
      	show "To NextLane:" 
      show next-lane-id
      ]
   
    		let y 0
  
   		if(next-lane-id = lane-fast-id) [
          set y lane-fast-ypos
        ]
   		if(next-lane-id = lane-medium-id) [
          set y lane-medium-ypos
        ]
   		if(next-lane-id = lane-slow-id) [
          set y lane-slow-ypos
        ]
        
   		set current-lane-id next-lane-id

        setxy xcor y
   
   	if debug [ 
        show "Lane is now: " 
        show current-lane-id
      ]
   
  end
   
    ;*********************** End Cars *********************************

  
;*********************** SETUP & GO *********************************


to setup
  clear-all
  set debug false
  setup-display
  setup-lanes ; do before cars, cars drive in lanes, duh
  setup-cars
  update-lanes ; determine congestion based on cars placed
  watch lead-car
  reset-ticks
end

to go
  update-lanes ; lanes need to know their parameters before the cars can ask them about it!
  
  
  ask lead-car [ set prev-xcor xcor  set prev-ycor ycor ]
  cars-drive
  tick
  ask lead-car [ set lead-car-moves (lead-car-moves + distancexy prev-xcor prev-ycor) ]
;  plot-data
  
end


  
  
to cars-drive
  ; vroom vroom
  
   if debug [ 
     show "---- New Driving Session  ----"
    ]
  
  
  ask cars [
    ; update all of my parameters
    evaluateConditions
    
    ; forumatate all of my alternatives
    formulateAlternatives
		
  ]  
  
  ; register all current conflicts
  
  ; resolve all conflicts
  
  ; everyone should know what theyre doing by now
  
  ; let them do what they decided
  
  ask cars [
    ; finally, we do what we argued for
    executeActions
  ]  
  
end
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  ;*********************** SETUP Car Placement and Initialization of Parameters *********************************
  	
to setup-cars
  if total-cars > world-width [
    user-message (word
      "There are too many cars for the amount of road.  Please decrease the NUMBER-OF-CARS slider to below "
      (world-width + 1) " and press the SETUP button again.  The setup has stopped.")
    stop
  ]
  let line (max-pycor * 2 / 3)
  
  set-default-shape turtles one-of ["car-east"]
  setup-traffic 90

  set lead-car one-of cars
  ask lead-car [
    set color sky
    if (Lane-Shift) [
      set agressive? true
    ]
  ]
end

    
to setup-traffic [ direction ]
    create-cars total-cars [
      
      ; give cars random current and preferred speeds
      set current-speed (random 10 + 1)
      set preferred-speed (random 10 + 1)
      
      ; give random cooperativeness-rating
      set cooperativeness-rating (random 10 + 1)
      
      set color 15
      set heading direction
      set label who
      ; assign them to a random lane (one that they might not like!)
      let chosenLaneYPos 0
      ifelse ((random 2) = 0) [
        set chosenLaneYPos lane-fast-ypos
        set current-lane-id lane-fast-id
      ] [
        ifelse ((random 2) = 0) [
           set chosenLaneYPos lane-medium-ypos
          set current-lane-id lane-medium-id

        ] [
          set chosenLaneYPos lane-slow-ypos
          set current-lane-id lane-slow-id
        ]
      ]
      
      set next-lane-id current-lane-id ; make him stay where he is for now
      
      if debug [ 
        show "---- Car Initialization ----"
      ]
      
      ; randomly place them on a position on the lane
      
      setxy random-xcor chosenLaneYPos

      ; fiddle with how they are placed on their lane
      separate-cars
      avoid-collision
  ]

end


  ; ********** basic setup collission avoidance ***************
  
to separate-cars ;; turtle procedure
  if any? other turtles-here [
    fd 2
    separate-cars
  ]
end

to avoid-collision
  set loop-counter (loop-counter + 1)
  let max-iterations 25
  if any? other cars-here [
    forward random 2
    if (loop-counter < 50) [
      avoid-collision
      separate-cars
    ]
  ]
end
  
;*********************** DISPLAY *********************************

to setup-display
  setup-dividers
  setup-grass
end

to setup-median
  ask patches [
    if (pycor = 0)
    [ set pcolor 9.9 ]
  ]
end

to setup-dividers
  let line (max-pycor * 2 / 3)
  
  setup-divider (max-pycor - line)
  setup-divider (min-pycor + line)
end

to setup-divider [ y ]
  create-dividers 1 [
    set shape "line"
    set color yellow   ; lanes on California roads are white
    setxy min-pxcor y ; start on the far left
    set heading 90    ; draw towards the right
  ]
  let line-length 2   ; default
  let line-spacing 1  ; default
  if (not Lane-Shift) [     ; user can choose if cars are allowed to change lanes
    set line-length 1
    set line-spacing 0
  ]

  repeat (world-width / (line-length + line-spacing)) [
    ask dividers [
      paint-line line-length line-spacing
    ]
  ]
  ask dividers [ die ] ;don't need the line painting agents any longer
end

to paint-line [ line-length line-spacing ]
  pen-down
  forward line-length
  pen-up
  forward line-spacing
end

to setup-grass
  ask patches [
    if (pycor > (max-pycor - 1) or pycor < (min-pycor + 1))
    [ set pcolor [0 255 0] ]
  ]
end
