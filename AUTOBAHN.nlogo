;; ADD assumptions

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

  worldEmissionLevel
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

  ; what value do i place on my choice
  chosenActionValue

  ; whats the current adjusted speed based on objective
  itsAdjustedSpeed

  ; speed -- how aggressive am i ( .1 to 1 )
  agressive


  ;;;;;;;;;; argumentation ;;;;;;;;;;;;

  ; D = <I, M, AR>
  ; Dialogue = <Agent Identity, Move Type, Argument>
  agentIdentity
  moveType

  ; AR = <A, V, S>
  ; Argument = <Action, Value, Stance for or against ( + | - )
  action
  actionParam1
  actionParam2
  value
  stance

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
  updateWorldEmission

  ask lead-car [ set prev-xcor xcor  set prev-ycor ycor ]
  cars-drive
  tick
  ask lead-car [ set lead-car-moves (lead-car-moves + distancexy prev-xcor prev-ycor) ]
  ;  plot-data

end

to updateWorldEmission
  let totalEmission 0

  ask lanee lane-fast-id [
    set totalEmission (totalEmission + emission-rating * current-congestion)
  ] ; fast-lane

  ask lanee lane-medium-id [
    set totalEmission (totalEmission + emission-rating * current-congestion)
  ] ; medium-lane

  ask lanee lane-slow-id [
    set totalEmission (totalEmission + emission-rating * current-congestion)
  ] ; slow-lane

  set worldEmissionLevel totalEmission
end


to cars-drive
  ; vroom vroom

  if debug [
    show "---- New Driving Session  ----"
    show "Getting best action...."
  ]

  ask cars [
    if not dummy [
      determineFeasibleActions
      decideBestAction

    ]
  ]
  if debug [
    show "Resolving arguments...."
  ]
  ask cars [
    if not dummy [
      if(laneChange) [
        resolveArguments
      ]
      waitForTurnEnd
    ]
  ]
  if debug [
    show "Performing action...."
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

  ; *************** Congestion *************
  let tmpAboveCong 0
  let tmpBelowCong 0
  let tmpCurrCong 0

  ;; above and below

  ; we are in fast lane
  if (current-lane-id = lane-fast-id)
  [
    ask lanee lane-medium-id [
      set tmpBelowCong ( current-congestion / getWorldCongestion )
    ] ; medium-lane
    set tmpAboveCong 1
  ]

  ; we are in middle lane
  if (current-lane-id = lane-medium-id)
  [
    ask lanee lane-fast-id [
      set tmpAboveCong ( current-congestion / getWorldCongestion )
    ] ; medium-lane

    ask lanee lane-slow-id [
      set tmpBelowCong ( current-congestion / getWorldCongestion )
    ] ; medium-lane
  ]

  ; we are in slow lane
  if (current-lane-id = lane-slow-id)
  [
    set tmpBelowCong 1
    ask lanee lane-medium-id [
      set tmpAboveCong ( current-congestion / getWorldCongestion )
    ] ; medium-lane
  ]

  ;; our lanes congestion
  ask lanee current-lane-id [
    set tmpCurrCong ( current-congestion / getWorldCongestion )
  ]

  set laneBelowRelativeCongestion tmpBelowCong
  set currentLaneRelativeCongestion tmpCurrCong
  set laneAboveRelativeCongestion tmpAboveCong



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

  ; determine my value of chosenAction





  let argumentation true
  if argumentation [
    ifelse chosenAction = "moveUp" OR chosenAction = "moveDown" [
      set laneChange true
    ] [
      set laneChange false
    ]
  ]
end
to-report getChosenActionValue
  ; what value do we place on our current chosen action?
  ;; simulate as if we already changed lanes
  let tmp-current-lane-id current-lane-id ;; save our current lane id in a tmp var
  adjustLane
  adhereToLaneRules "max"
  adhereToLaneRules "min"
  let tmp-next-speed next-speed

  ;; reset back to what they were
  let tmp-next-lane-id next-lane-id
  set next-lane-id tmp-current-lane-id
  adjustLane
  adhereToLaneRules "max"
  adhereToLaneRules "min"
  set next-lane-id tmp-next-lane-id


  ;; how does this differ from our adjusted value?

  set chosenActionValue abs ( tmp-next-speed - itsAdjustedSpeed )

end
to-report decideBestTravelTimeAction

  let currentLaneMin 0
  let currentLaneMax 0
  let speedFactor travelTimeAggresiveness
  set itsAdjustedSpeed (preferred-speed + speedFactor )
  ask lanee current-lane-id [
    set currentLaneMin min-speed
    set currentLaneMax max-speed
  ]

  ; fast people ignore their preferred-speed
  if( currentLaneMax < (preferred-speed + speedFactor ) )[
    ;; this lane is too slow for us
    if canAccelerate [
      report "accelerate"

    ]
    if canMoveUp [
      report "moveUp"
    ]


  ]

  ;; is this lane too fast for me?
  if( currentLaneMin > (preferred-speed + speedFactor ) )[
    ;; this lane is too slow for us
    if canMoveDown [
      report "moveDown"
    ]
    if canDecelerate [
      report "decelerate"
    ]

  ]

  if ( current-speed = (preferred-speed + speedFactor) ) and canMaintainSpeed [
    report "maintainSpeed"
  ]

  report ""

end

to-report decideBestEmissionAction
  let currentLaneMin 0
  let currentLaneMax 0
  let speedFactor emissionFriendliness
  set itsAdjustedSpeed (preferred-speed - speedFactor )
  ask lanee current-lane-id [
    set currentLaneMin min-speed
    set currentLaneMax max-speed
  ]

  ; we are willing to go below our preferred speed in order to go to a less emission lane
  ; if the lane i am in has a max that is below my adjusted preferred speed, go up
  if( currentLaneMax < (preferred-speed - speedFactor ) )[
    ;; this lane is too slow for us
    if canMoveUp [
      report "moveUp"
    ]
    if canAccelerate [
      report "accelerate"
    ]

  ]

  ;; is this lane too fast for me?
  if( currentLaneMin > (preferred-speed - speedFactor ) )[
    ;; this lane is too slow for us
    if canMoveDown [
      report "moveDown"
    ]
    if canDecelerate [
      report "decelerate"
    ]

  ]

  if ( current-speed = (preferred-speed - speedFactor) ) and canMaintainSpeed [
    report "maintainSpeed"
  ]

  report ""
end

to-report decideBestCongestionAction
  let currentLaneMin 0
  let currentLaneMax 0
  let cAw congestionAwareness
  let rLC currentLaneRelativeCongestion
  let laneNCost ( ( cAw * ( 1 - rLC ) ) )
  let laneNPlus1Cost  ( ( cAw * ( 1 - laneAboveRelativeCongestion ) ) ) ; an unfeasable lane is set to '1' (full), so: this equates to zero
  let laneNMinus1Cost  ( ( cAw * ( 1 - laneBelowRelativeCongestion ) ) )

  let adjustedSpeed preferred-speed

  ask lanee current-lane-id [
    set currentLaneMin min-speed
    set currentLaneMax max-speed
  ]

  let upLaneCongCost (laneNPlus1Cost - laneNCost)
  let downLaneCongCost (laneNMinus1Cost - laneNCost)

  set adjustedSpeed (preferred-speed + upLaneCongCost)


  show "preferred-speed"
  show preferred-speed

  show "upLaneCongCost"
  show upLaneCongCost

  show "adjustedSpeed"
  show adjustedSpeed

  show "downLaneCongCost"
  show downLaneCongCost

  if( currentLaneMax < ( adjustedSpeed ) )[
    ;; this lane is too slow for us
    if canMoveUp [
      report "moveUp"
    ]
    if canAccelerate [
      report "accelerate"
    ]
  ]

  set adjustedSpeed (preferred-speed - downLaneCongCost)

    show "adjustedSpeed"
  show adjustedSpeed

  ;; is this lane too fast for me?
  if( currentLaneMin > ( adjustedSpeed ) )[
    ;; this lane is too slow for us
    if canMoveDown [
      report "moveDown"
    ]
    if canDecelerate [
      report "decelerate"
    ]

  ]

  if ( current-speed = preferred-speed ) and canMaintainSpeed [
    report "maintainSpeed"
  ]

  report ""

end

to-report getValueOfObjectiveAction [ objectiveType ]; car procedure
                                                     ; this procedure reports the value that a vehicle places on a decision
  let decidedAction ""
  if( objectiveType = "travelTime" ) [
    set decidedAction decideBestTravelTimeAction
  ]

  if( objectiveType = "emission" ) [
    set decidedAction decideBestEmissionAction
  ]

  if( objectiveType = "congestion" ) [
    set decidedAction decideBestEmissionAction ;TODO --- change to congestion after fixing congestion --- also change where this was copied from too
  ]

  decideBestAction ; reset whatever they had before

end
to resolveArguments ; car procedure
  let resolvedAllArguments false

  if (laneChange) [
    ;; We are a vehicle that is changing lanes. Congrats!
    ; the current protocol is as follows:

    ; 1. resolve any cuttoff arguments
    ; 1.1. ask car im cutting off if its ok to cut them off

    ;; there is someone we will cut off, argue with him/her!
    ; createDialogue["open"]["cutoff"][true]
    ;; dialogue created, get the other vehicles response
    ; let response getCarResponse

  ]

end
to createDialogue [ move actionType stanceForVal ] ; car procedure
                                                   ; create dialogue

  ; D = <I, M, AR>
  ; Dialogue = <Agent Identity, Move Type, Argument>
  set agentIdentity self
  set moveType move

  ; AR = <A, V, S>
  ; Argument = <Action, Value, Stance for or against ( + | - )
  set action actionType
  set value chosenActionValue
  set stance stanceForVal

end

to-report getCarResponse
  ;; car we are cutting off will do three things
  ; 1. generates value of next best action if he loses
  let carNextBestActionValue 0
  ; 2. generates value he would choose if in the same position as the other vehicle
  let carPriority 0
  let carSimulationValue 0
  ; 3. generates the current value he places on staying in this lane
  let carStayingValue 0
  ;; but before all that, is he even claiming the space we want?

  let otherVehicle nobody

  if (chosenAction = "moveDown") [
    set otherVehicle getCarBelowAndBack
  ]
  if (chosenAction = "moveUp" ) [
    set otherVehicle getCarAboveAndBack
  ]

  ifelse (otherVehicle = nobody) [
    report true
  ] [
    ask otherVehicle [
      ; this is of the car being cutoff
      if ( NOT laneChange ) [ ;; the vehicle is not changing lanes, meaning that he wishes to stay in his current one, buckle down and get reedy for an argument!
        set carStayingValue chosenActionValue
        set carPriority currentPriority
        let previousSpotAheadClaimed spotAheadClaimed
        let previousSelf self

        set spotAheadClaimed true ; just for modeling purposes, like, what would happen if this vehicle had to make a different choice?
        determineFeasibleActions
        decideBestAction

        set carNextBestActionValue chosenActionValue

        set spotAheadClaimed previousSpotAheadClaimed ; reset it back to what it was
        determineFeasibleActions
        decideBestAction
        ; TODO TODO TODO TODO

        show "carStayingValue"
        show carStayingValue
      ]
    ]
  ]
  report true


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

  set laneChange false ;; if we changed a lane, it doesnt affect our next move!
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

to-report getCarFarAbove ; car procedure
  let carVar nobody
  let y 0

  if(current-lane-id = lane-slow-id) [

    ask lanee (current-lane-id + 2) [
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
to-report getCarCuttingOff
  let carVar nobody
  let y 0

  if(current-lane-id = lane-slow-id) [
    ask lanee (current-lane-id + 1) [
      	set y y-pos
    	]
    if( any? cars-on patch (xcor - 1) y ) [
      ask cars-on patch xcor y [
        set carVar self
      ]
    ]
  ]
  if(current-lane-id = lane-fast-id) [
    ask lanee (current-lane-id - 1 ) [
      	set y y-pos
    	]
    if( any? cars-on patch (xcor - 1) y ) [
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

to-report getCarAboveAndBack ; car procedure
  let carVar nobody
  let y 0

  if(laneAboveInBounds) [

    ask lanee (current-lane-id + 1) [
      	set y y-pos
    	]

    if( any? cars-on patch (xcor - 1) y ) [
      ask cars-on patch (xcor - 1) y [
        set carVar self
      ]

    ]

  ]
  report carVar
end

to-report getCarBelowAndBack ; car procedure
  let carVar nobody
  let y 0
  let xBack 0

  if(laneBelowInBounds) [
    ask lanee (current-lane-id - 1) [
      	set y y-pos
    	]

    if( any? cars-on patch (xcor - 1) y ) [
      ask cars-on patch (xcor - 1) y [
        set carVar self
      ]

    ]

  ]
  report carVar
end
to-report getCarFarBelow; car procedure
  let carVar nobody
  let y 0

  if(current-lane-id = lane-fast-id) [
    ask lanee (current-lane-id - 2) [
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

    set currentPriority "emission"

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
