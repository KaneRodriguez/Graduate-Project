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


  ;        adjacent vehicles available through - getCarAbove/Below/Ahead getCarAheadTooSlow
 	recommendedAction

  ; 		objectives TODO



  ; dummy cars
  dummy

  ; *********************************   environmental conditions    *******************************************

  laneAboveInBounds
  laneBelowInBounds

  laneAboveOccupied
  laneBelowOccupied
  spotAheadOccupied

  laneAboveClaimed
  laneBelowClaimed
  spotAheadClaimed

  abovePreferredSpeed
  belowPreferredSpeed
  atPreferredSpeed

  wantFasterLane
  wantSlowerLane

  laneBelowRelativeCongestion
  currentLaneRelativeCongestion
  laneAboveRelativeCongestion

  laneAboveRelativeEmission
  laneBelowRelativeEmission
  currentLaneRelativeEmission

  speedDifferential
  normalizedCooperativeness

  ; *********************************   other conditions    *******************************************


  ; does action involve lane change? (true or false)
  laneChange

  ; IMPORTANT - what priority are we
  currentPriority

  ; what did i choose
  chosenAction

  ; speed -- how aggressive am i ( .1 to 1 )
  agressive

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
        set max-speed 1.0
        set min-speed .7
        set emission-rating 3
        set y-pos lane-fast-ypos
      ] ; fast-lane

      ask lanee lane-medium-id [
        set max-speed .6
        set min-speed .4
        set emission-rating 2
        set y-pos lane-medium-ypos
      ] ; medium-lane

      ask lanee lane-slow-id [
        set max-speed .3
        set min-speed .1
        set emission-rating 1
        set y-pos lane-slow-ypos
      ] ; slow-lane

    end


    ;*********************** End Lanes *********************************

;*********************** Cars *********************************

      ; methods

      to getRecommendedAction ; car procedure
                   ; matchSpeedOfApproachingCar moveUpLane moveDownLane speedUp slowDown staySameSpeed
        set recommendedAction ""



        ;; < since NOT wantSlowerLane AND NOT wantFasterLane AND NOT abovePreferredSpeed AND NOT belowPreferredSpeed AND (getCarAhead = nobody); we are in the speed we want, stay >

        if ( NOT wantSlowerLane AND NOT wantFasterLane AND NOT abovePreferredSpeed AND NOT belowPreferredSpeed AND (getCarAhead = nobody) ) [
          set recommendedAction "staySameSpeed"
        ]

        if ( NOT wantSlowerLane AND NOT wantFasterLane AND belowPreferredSpeed AND (getCarAhead = nobody) ) [
          set recommendedAction "speedUp"
        ]

        if ( NOT wantSlowerLane AND NOT wantFasterLane AND abovePreferredSpeed and (getCarAhead = nobody ) ) [
          set recommendedAction "slowDown"
        ]

        if ( wantFasterLane AND getLaneAboveAvailability ) [
          set recommendedAction "moveUpLane"
        ]

        if ( wantSlowerLane AND getLaneBelowAvailability ) [
          set recommendedAction "moveDownLane"
        ]

        if ( ( getCarAhead != nobody ) AND NOT getLaneAboveAvailability AND NOT getLaneBelowAvailability ) [
          set recommendedAction "matchApproachingCarSpeed"
        ]

        if ( getCarAheadTooSlow AND getLaneAboveAvailability AND belowPreferredSpeed) [
          set recommendedAction "moveUpLane"
        ]
        if( (getCarAhead != nobody) and [current-speed] of getCarAhead > preferred-speed ) [
          set recommendedAction  "slowDown"
        ]
        if recommendedAction = "" [
            ; uh-oh, we don't know what to do
            if ( getCarAhead != nobody ) [ ; is there a car ahead?
                set recommendedAction "matchApproachingCarSpeed"
            ]
        ]





        ;; if( any? other cars-on patch-here ) [ displayCarStatus ]
      end
			to-report getLaneAboveAvailability

        if( laneAboveFeasible and (getCarAbove = nobody) ) [
          report true
        ]
        report false
        end

        to-report getLaneBelowAvailability

        if( laneBelowFeasible and (getCarBelow = nobody) ) [
          report true
        ]
        report false
        end

          to-report getCarAheadTooSlow
            let carAhead getCarAhead
            let currentLaneMin 0
            let carAheadTooSlow false

            ask lanee current-lane-id [
              set currentLaneMin min-speed
            ]

            if( carAhead != nobody ) [
             ; is this car going too slow for his lane??
              let speedOfCarAhead 0
              ask carAhead [
                set speedOfCarAhead current-speed
              ]

              if( speedOfCarAhead < currentLaneMin ) [
                set carAheadTooSlow true
              ]
            ]
            report carAheadTooSlow
          end





      to evaluateConditions ; car procedure
        evaluateLaneConditions ; gives me info about what lanes i want and what is possible
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
            show "CarAhead:"
            show getCarAhead
            show "recommendedAction:"
            show recommendedAction
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

        to executeActions ; car procedure

          if debug [
           show "-- Car Executing Choice --"
            displayCarStatus
          ]

          executeChoice recommendedAction
          ifelse (not dummy) [
            adjustLane ; CALL before changing speed
            adjustSpeed
          ] [
           forward current-speed
          ]
        end

        to executeChoice [ choice ]
          if( choice = "matchApproachingCarSpeed") [
           ; matchSpeedOfApproachingCar moveUpLane moveDownLane speedUp slowDown staySameSpeed
            matchApproachingCarSpeed
          ]
          if( choice = "moveUpLane") [
            moveUpLane
          ]
          if( choice = "moveDownLane") [
            moveDownLane
          ]
          if( choice = "speedUp") [
            speedUp
          ]
          if( choice = "slowDown") [
            slowDown
          ]
          if( choice = "staySameSpeed") [
            staySameSpeed
          ]
        end


          to matchApproachingCarSpeed  ; car procedure
            let newSpeed 0
            let carAhead getCarAhead
            ifelse( carAhead != nobody ) [
              ask carAhead [
              set newSpeed current-speed
              ]
            ] [
              set newSpeed current-speed
            ]

            set next-speed newSpeed
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
    if not dummy [
      determineFeasibleActions
      decideBestAction
    ]
  ]

  ask cars [
    if not dummy [
      if(laneChange) [
        resolveArguments
      ]
      waitForTurnEnd
    ]
  ]

  ask cars [
    ifelse not dummy [
      performAction
    ] [
     fd current-speed 
    ]
  ]

end

  ;; ********************* Expert System **************************




  to determineFeasibleActions

  ifelse ycor = lane-slow-ypos
  [ set laneBelowInBounds false]
  [ set laneBelowInBounds true ]

  ifelse ycor = lane-fast-ypos
  [ set laneAboveInBounds false]
  [ set laneAboveInBounds true ]

  ; am i above or below my current speed?

  ifelse current-speed > preferred-speed
  [ set abovePreferredSpeed true]
  [ set abovePreferredSpeed false ]

  ifelse current-speed < preferred-speed
  [ set belowPreferredSpeed true]
  [ set belowPreferredSpeed false ]

  ifelse current-speed = preferred-speed
  [ set atPreferredSpeed true]
  [ set atPreferredSpeed false ]

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

  ; are lanes above, below, or ahead occupied? // NOTE: Call this after the bounds are determined for lanes

  ifelse (getCarAhead != nobody)
  [ set spotAheadOccupied true]
  [ set spotAheadOccupied false ]

  ifelse (getCarAbove != nobody)
  [ set laneAboveOccupied true]
  [ set laneAboveOccupied false ]

  ifelse (getCarBelow != nobody)
  [ set laneBelowOccupied true]
  [ set laneBelowOccupied false ]

; are lanes above, below, or ahead claimed? This is set when we win/lose arguments, leave them alone for now

  ; laneAboveClaimed
  ; laneBelowClaimed
  ; spotAheadClaimed

  ; determine the normalized cooperativeness, speedDifferential, lane above and below relative congestion/emission // NOTE: Call this after the bounds are determined for lanes

; *************** Congestion *************8



  ifelse (laneBelowInBounds) [
       let worldCongestion getWorldCongestion
       let itsCongestion 0

       ask lanee (current-lane-id - 1) [
         set itsCongestion current-congestion
       ]

       ifelse (worldCongestion > 0) [
         set laneBelowRelativeCongestion (itsCongestion / worldCongestion)
       ] [
         set laneBelowRelativeCongestion 0
       ]
  ] [
      set laneBelowRelativeCongestion 0
  ]

  ifelse (laneAboveInBounds) [
       let worldCongestion getWorldCongestion
       let itsCongestion 0

       ask lanee (current-lane-id + 1) [
         set itsCongestion current-congestion
       ]

       ifelse (worldCongestion > 0) [
         set laneAboveRelativeCongestion (itsCongestion / worldCongestion)
       ] [
         set laneAboveRelativeCongestion 0
       ]
  ] [
      set laneAboveRelativeCongestion 0
  ]

    ifelse (true) [  ;; got lazy, dont judge me, Ctl+C, Ctl+V master
       let worldCongestion getWorldCongestion
       let itsCongestion 0

       ask lanee (current-lane-id) [
         set itsCongestion current-congestion
       ]

       ifelse (worldCongestion > 0) [
         set currentLaneRelativeCongestion (itsCongestion / worldCongestion)
       ] [
         set currentLaneRelativeCongestion 0
       ]
  ] [
      set currentLaneRelativeCongestion 0
  ]




   ; *************** Emission *************8



  ifelse (laneBelowInBounds) [
       let worldEmission getWorldEmission
       let itsEmission 0

       ask lanee (current-lane-id - 1) [
         set itsEmission emission-rating
       ]

       ifelse (worldEmission > 0) [
         set laneBelowRelativeEmission (itsEmission / worldEmission)
       ] [
         set laneBelowRelativeEmission 0
       ]
  ] [
      set laneBelowRelativeEmission 0
  ]

  ifelse (laneAboveInBounds) [
       let worldEmission getWorldEmission
       let itsEmission 0

       ask lanee (current-lane-id + 1) [
         set itsEmission emission-rating
       ]

       ifelse (worldEmission > 0) [
         set laneAboveRelativeEmission (itsEmission / worldEmission)
       ] [
         set laneAboveRelativeEmission 0
       ]
  ] [
      set laneAboveRelativeEmission 0
  ]

    ifelse (true) [  ;; got lazy, dont judge me, Ctl+C, Ctl+V master
       let worldEmission getWorldEmission
       let itsEmission 0

       ask lanee (current-lane-id) [
         set itsEmission emission-rating
       ]

       ifelse (worldEmission > 0) [
         set currentLaneRelativeEmission (itsEmission / worldEmission)
       ] [
         set currentLaneRelativeEmission 0
       ]
  ] [
      set currentLaneRelativeEmission 0
  ]


  ; ******* bleh - speed differential and normalizedCooperativeness

  let worldMax getWorldMaxSpeed
  ifelse ( worldMax > 0) [
    set speedDifferential ( (preferred-speed - current-speed) / getWorldMaxSpeed )
  ] [
    set speedDifferential 0
  ]


  if currentPriority = "emission" [
      set normalizedCooperativeness (1 - abs speedDifferential + 1 - currentLaneRelativeEmission + (cooperativeness-rating) / 10 )

      set normalizedCooperativeness min list normalizedCooperativeness 1
    ]
  if currentPriority = "congestion" [
      set normalizedCooperativeness (1 - abs speedDifferential + 1 - currentLaneRelativeCongestion + (cooperativeness-rating) / 10 )

      set normalizedCooperativeness min list normalizedCooperativeness 1
    ]
  if currentPriority = "travelTime" [
      set normalizedCooperativeness (1 - abs speedDifferential + (cooperativeness-rating) / 10 )

      set normalizedCooperativeness min list normalizedCooperativeness 1
    ]

end

  ; *********** Possible Actions ************8

  to-report canMoveUp
    ; 3 conditions - Bounds, Occupation, Claim
    if(laneAboveInBounds AND not laneAboveOccupied AND not laneAboveClaimed) [
      report true
    ]
    report false
end

  to-report canMoveDown
    ; 3 conditions - Bounds, Occupation, Claim
    if(laneBelowInBounds AND not laneBelowOccupied AND not laneBelowClaimed) [
      report true
    ]
    report false
end

   to-report canMaintainSpeed
    ; as long as spot ahead isnt occupied or claimed
    if(not spotAheadOccupied AND not spotAheadClaimed) [
      report true
    ]
    report false
end

   to-report canDecelerate
    ; current speed not below lane min : NOTE - Could change! Could have no requirements to stop!
    let currentMax 0
    let currentMin 0

    ask lanee current-lane-id [
      set currentMax max-speed
      set currentMin min-speed
    ]

    if(current-speed > currentMin) [
     report true
    ]
    report false

end

   to-report canAccelerate
    ; current speed not above lane max : NOTE - Could change! Could have no requirements to stop!
    let currentMax 0
    let currentMin 0

    ask lanee current-lane-id [
      set currentMax max-speed
      set currentMin min-speed
    ]

    if(current-speed < currentMax) [
     report true
    ]
    report false

end

  ; *********** End Possible Actions ************8


  ; *********** Perform Actions ************8

            to speedUp ; car procedure
            set next-speed (current-speed + car-acceleration)
            adhereToLaneRules "max"
          end
          to slowDown ; car procedure
            set next-speed (current-speed - car-deceleration)
            adhereToLaneRules "min"
          end
          to staySameSpeed ; car procedure
            set next-speed current-speed
          end
          to moveUpLane ; car procedure
            set next-lane-id (current-lane-id + 1)
            adhereToLaneRules "min"
          end

            to moveDownLane ; car procedure
            set next-lane-id (current-lane-id - 1)
            adhereToLaneRules "max"
          end

          to adhereToLaneRules [ ruleType ]
            let currentMax 0
            let currentMin 0

            ask lanee next-lane-id [
              set currentMax max-speed
              set currentMin min-speed
            ]

            if(next-speed > currentMax and ruleType = "max") [
              set next-speed currentMax
            ]
            if(next-speed < currentMin and ruleType = "min") [
              set next-speed currentMin
            ]
          end

  ; *********** End Perform Actions ************8

  to decideBestAction
    let decidedAction ""
    if( currentPriority = "travelTime" ) [
      set decidedAction decideBestTravelTimeAction
    ]

    if( currentPriority = "emission" ) [
      set decidedAction decideBestEmissionAction
    ]

    if( currentPriority = "congestion" ) [
      set decidedAction decideBestCongestionAction
    ]
    if decidedAction = "" [
     ; still no decision? Just arbitrarily, but conservatively, pick one!
     ; OR just stop!
      set decidedAction "decelerate"
    ]
    set chosenAction decidedAction
end

  to-report decideBestTravelTimeAction

    let currentLaneMin 0
    let currentLaneMax 0
    let speedFactor travelTimeAggresiveness

    ask lanee current-lane-id [
      set currentLaneMin min-speed
      set currentLaneMax max-speed
    ]

    if belowPreferredSpeed [
      ifelse canMoveUp [
        if wantFasterLane OR ( currentLaneMax < ( current-speed + speedFactor) ) [
          report "moveUp"
        ]
      ] [
        ;; cant move up, lets accelerate
        if canAccelerate [
          report "accelerate"
        ]
      ]
    ]

  if abovePreferredSpeed [
    ifelse canMoveDown [
      if ( currentLaneMin < ( current-speed + speedFactor) ) [
        report "moveDown"
      ]
    ] [
        ;; cant move down, lets decelerate
        if canDecelerate [
          report "decelerate"
        ]
      ]
    ]

  if atPreferredSpeed and canMaintainSpeed [
    report "maintainSpeed"
  ]

   report ""

end

  to-report decideBestEmissionAction
    let currentLaneMin 0
    let currentLaneMax 0
    let emissionFactor ( emissionFriendliness )

    ask lanee current-lane-id [
      set currentLaneMin min-speed
      set currentLaneMax max-speed
    ]
    
    if ( currentLaneMin > ( preferred-speed - emissionFactor) )  [
      if canMoveDown [
        report "moveDown"
      ] 
    ]
    
    if ( currentLaneMax < ( preferred-speed - emissionFactor) ) [
      if canMoveUp [
          report "moveUp"
      ] 
    ]
    
    if belowPreferredSpeed [
      if canDecelerate [
        report "decelerate"
      ] 
    ]
    if abovePreferredSpeed [
      if canAccelerate [
        report "accelerate"
      ] 
    ]

  if atPreferredSpeed and canMaintainSpeed [
    report "maintainSpeed"
  ]

   report ""
end

  to-report decideBestCongestionAction
    let currentLaneMin 0
    let currentLaneMax 0

    ask lanee current-lane-id [
      set currentLaneMin min-speed
      set currentLaneMax max-speed
    ]
    if canMoveUp [
      if ( ( ( currentLaneRelativeCongestion - laneAboveRelativeCongestion) + preferred-speed ) > currentLaneMax) [
         report "moveUp"
      ]
    ]
    if canMoveDown [
      if ( ( ( currentLaneRelativeCongestion - laneAboveRelativeCongestion) + preferred-speed ) < currentLaneMin) [
         report "moveDown"
      ]
    ]
    
    if belowPreferredSpeed [
      if canDecelerate [
        report "decelerate"
      ] 
    ]
    if abovePreferredSpeed [
      if canAccelerate [
        report "accelerate"
      ] 
    ]

  if atPreferredSpeed and canMaintainSpeed [
    report "maintainSpeed"
  ]

   report ""

end

  to resolveArguments

end

  to waitForTurnEnd

end

  to performAction
    ;; 5 possible actions

    ifelse chosenAction = "moveUp" [ moveUpLane ]
    [ ifelse chosenAction = "moveDown" [ moveDownLane ]
    [ ifelse chosenAction = "accelerate" [ speedUp ]
    [ ifelse chosenAction = "decelerate" [ slowDown ]
      [ ifelse chosenAction = "maintainSpeed" [ staySameSpeed ] []

    ] ] ] ]

    adjustLane ;; call before adjusting speed
    adjustSpeed

end



  ; ******* Evaluating Environmental Conditions ***************;
  to-report getWorldMaxSpeed
    let worldMax 0
   ask lanee lane-fast-id [
     set worldMax max-speed
   ]
   report worldMax
end
  to-report getWorldCongestion
    let totalWorldCongestion 0

      ask lanee lane-fast-id [
        set totalWorldCongestion (totalWorldCongestion + current-congestion)
      ] ; fast-lane

      ask lanee lane-medium-id [
        set totalWorldCongestion (totalWorldCongestion + current-congestion)
      ] ; medium-lane

      ask lanee lane-slow-id [
        set totalWorldCongestion (totalWorldCongestion + current-congestion)
      ] ; slow-lane

      report totalWorldCongestion

end

  to-report getWorldEmission
    let totalWorldEmission 0

      ask lanee lane-fast-id [
        set totalWorldEmission (totalWorldEmission + emission-rating)
      ] ; fast-lane

      ask lanee lane-medium-id [
        set totalWorldEmission (totalWorldEmission + emission-rating)
      ] ; medium-lane

      ask lanee lane-slow-id [
        set totalWorldEmission (totalWorldEmission + emission-rating)
      ] ; slow-lane

      report totalWorldEmission

end
      to-report getCarAhead ; car procedure
            let carVar nobody
            let myX xcor
            ifelse ( any? other cars-on patch-here ) [

              ask other cars-on patch-here [
                if( xcor > myX ) [
                 set carVar self
                ]

              ]
            ] [
            ;; nooone in my spot, so look further ahead
              ask cars-on patch-ahead 1 [
                set carVar self
              ]
            ]
            report carVar
          end

          to-report getCarAbove ; car procedure
            let carVar nobody
            let y 0

            if(laneAboveInBounds) [

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

            if(laneBelowInBounds) [
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

  to initializeCarParameters
    ; * Note: does not initialize all yet

  set laneAboveInBounds false
  set laneBelowInBounds false

  set laneAboveOccupied false
  set laneBelowOccupied false
  set spotAheadOccupied false

  set laneAboveClaimed false
  set laneBelowClaimed false
  set spotAheadClaimed false

  set abovePreferredSpeed false
  set belowPreferredSpeed false
  set atPreferredSpeed false

  set wantFasterLane false
  set wantSlowerLane false

  set laneBelowRelativeCongestion false
  set currentLaneRelativeCongestion false
  set laneAboveRelativeCongestion false

  set laneAboveRelativeEmission false
  set laneBelowRelativeEmission false
  set currentLaneRelativeEmission false

  set speedDifferential 0
  set normalizedCooperativeness 0

  set laneChange false

  set currentPriority "none"

end
  to displayCar
    show "-------------------- Car Parameters ----------------"
    show self

  show "laneAboveInBounds"
  show laneAboveInBounds
  show "laneBelowInBounds"
  show laneBelowInBounds

  show "laneAboveOccupied"
  show laneAboveOccupied
  show "laneBelowOccupied"
  show laneBelowOccupied
  show "spotAheadOccupied"
  show spotAheadOccupied

  show "laneAboveClaimed"
  show laneAboveClaimed
  show "laneBelowClaimed"
  show laneBelowClaimed
  show "spotAheadClaimed"
  show spotAheadClaimed

  show "abovePreferredSpeed"
  show abovePreferredSpeed
  show "belowPreferredSpeed"
  show belowPreferredSpeed
  show "atPreferredSpeed"
  show atPreferredSpeed

  show "wantFasterLane"
  show wantFasterLane
  show "wantSlowerLane"
  show wantSlowerLane

  show "laneBelowRelativeCongestion"
  show laneBelowRelativeCongestion
  show "currentLaneRelativeCongestion"
  show currentLaneRelativeCongestion
  show "laneAboveRelativeCongestion"
  show laneAboveRelativeCongestion

  show "laneAboveRelativeEmission"
  show laneAboveRelativeEmission
  show "laneBelowRelativeEmission"
  show laneBelowRelativeEmission
  show "currentLaneRelativeEmission"
  show currentLaneRelativeEmission

  show "speedDifferential"
  show speedDifferential
  show "normalizedCooperativeness"
  show normalizedCooperativeness

  show "laneChange"
  show laneChange

  show "currentPriority"
  show currentPriority
end
  ; ******* Performing Actions ***************

            to adjustSpeed  ; car procedure
            ; this is where we ACTUALLY adjust the speed
            let carAhead getCarAhead
            let carAheadX 0
            let carAheadSpeed 0
            if( carAhead != nobody ) [
              ask carAhead [
                set carAheadX xcor
                set carAheadSpeed next-speed
              ]
              if(xcor + next-speed > (carAheadX + carAheadSpeed) ) [
                set next-speed (.9 * carAheadSpeed )
              ]
            ]
            
            set current-speed next-speed
            fd current-speed
          end


 to adjustLane ; car procedure

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





  ;*********************** SETUP Car Placement and Initialization of Parameters *********************************

to setup-cars

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
  let laneOneAmount 0
  let laneTwoAmount 0
  let laneThreeAmount 0
  let dummyCount 0
  let emissionAmount emissionCars
  let congestionAmount congestionCars
  let speedAmount speedCars
  
    create-cars congestionAmount [

      initializeCarParameters ; doesnt include all for now

      ; give cars random current and preferred speeds
      set current-speed ( (random 10 + 1) / 10)
      set preferred-speed ( (random 10 + 1) / 10 )

      set currentPriority "congestion"

      ifelse( dummyCount < dummy-cars ) [
       set dummy true
       set color white
       set dummyCount (dummyCount + 1)
      ] [ set dummy false
     set color 15 ]
set color brown
      ; give random cooperativeness-rating
      set cooperativeness-rating (random 10 + 1)


      set heading direction
      set label who
      ; assign them to a random lane (one that they might not like!)
      let chosenLaneYPos 0
      ifelse ((random 2) = 0 and laneOneAmount < world-width) [
        set chosenLaneYPos lane-fast-ypos
        set current-lane-id lane-fast-id
        set laneOneAmount (laneOneAmount + 1)
      ] [
        ifelse ((random 2) = 0  and laneOneAmount < world-width) [
           set chosenLaneYPos lane-medium-ypos
          set current-lane-id lane-medium-id
          set laneTwoAmount (laneTwoAmount + 1)
        ] [
          ifelse (laneThreeAmount < world-width) [
          set chosenLaneYPos lane-slow-ypos
          set current-lane-id lane-slow-id
          set laneThreeAmount (laneThreeAmount + 1)
          ] [
            ;; way too many cars!
            user-message "Way too many cars!"
            stop
          ]
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
create-cars emissionAmount [

      initializeCarParameters ; doesnt include all for now

      ; give cars random current and preferred speeds
      set current-speed ( (random 10 + 1) / 10)
      set preferred-speed ( (random 10 + 1) / 10 )

      set currentPriority "emmission"

      ifelse( dummyCount < dummy-cars ) [
       set dummy true
       set color white
       set dummyCount (dummyCount + 1)
      ] [ set dummy false
     set color 15 ]
set color green
      ; give random cooperativeness-rating
      set cooperativeness-rating (random 10 + 1)


      set heading direction
      set label who
      ; assign them to a random lane (one that they might not like!)
      let chosenLaneYPos 0
      ifelse ((random 2) = 0 and laneOneAmount < world-width) [
        set chosenLaneYPos lane-fast-ypos
        set current-lane-id lane-fast-id
        set laneOneAmount (laneOneAmount + 1)
      ] [
        ifelse ((random 2) = 0  and laneOneAmount < world-width) [
           set chosenLaneYPos lane-medium-ypos
          set current-lane-id lane-medium-id
          set laneTwoAmount (laneTwoAmount + 1)
        ] [
          ifelse (laneThreeAmount < world-width) [
          set chosenLaneYPos lane-slow-ypos
          set current-lane-id lane-slow-id
          set laneThreeAmount (laneThreeAmount + 1)
          ] [
            ;; way too many cars!
            user-message "Way too many cars!"
            stop
          ]
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
  create-cars speedAmount [

      initializeCarParameters ; doesnt include all for now

      ; give cars random current and preferred speeds
      set current-speed ( (random 10 + 1) / 10)
      set preferred-speed ( (random 10 + 1) / 10 )

      set currentPriority "travelTime"

      ifelse( dummyCount < dummy-cars ) [
       set dummy true
       set color white
       set dummyCount (dummyCount + 1)
      ] [ set dummy false
     set color 15 ]
set color red
      ; give random cooperativeness-rating
      set cooperativeness-rating (random 10 + 1)


      set heading direction
      set label who
      ; assign them to a random lane (one that they might not like!)
      let chosenLaneYPos 0
      ifelse ((random 2) = 0 and laneOneAmount < world-width) [
        set chosenLaneYPos lane-fast-ypos
        set current-lane-id lane-fast-id
        set laneOneAmount (laneOneAmount + 1)
      ] [
        ifelse ((random 2) = 0  and laneOneAmount < world-width) [
           set chosenLaneYPos lane-medium-ypos
          set current-lane-id lane-medium-id
          set laneTwoAmount (laneTwoAmount + 1)
        ] [
          ifelse (laneThreeAmount < world-width) [
          set chosenLaneYPos lane-slow-ypos
          set current-lane-id lane-slow-id
          set laneThreeAmount (laneThreeAmount + 1)
          ] [
            ;; way too many cars!
            user-message "Way too many cars!"
            stop
          ]
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
