marker -tasks

0 constant PAUSED
1 constant SKIPPED

struct
    cell field: .next
    cell field: .status
    cell field: .sp
    cell field: .rp
    cell field: .ip
constant Task

here Task allot constant INTERPRETER
INTERPRETER INTERPRETER .next !
SKIPPED INTERPRETER .status !

128 variable! var-task-stack-size
64  variable! var-task-rstack-size
INTERPRETER variable! var-last-task
INTERPRETER variable! var-current-task
variable var-xt-pause

: last-task ( -- task ) var-last-task @ ;
: last-task! ( task -- ) var-last-task ! ;
: current-task ( -- task ) var-current-task @ ;
: current-task! ( task -- ) var-current-task ! ;

: alloc-data-stack ( -- a )
    var-task-stack-size @ allot here ;

: alloc-return-stack ( -- a )
    var-task-rstack-size @ allot here ;

: task: ( "name" ) ( -- task )
    create
        here                                 \ task header begins here
        Task allot                           \ make room for task header
        SKIPPED             over .status !   \ new status is SKIPPED
        last-task .next @   over .next !     \ this.next = last-task.next
        dup last-task .next !                \ last-task.next = this
        alloc-data-stack    over .sp !       \ this.sp = allocated
        alloc-return-stack  over .rp !       \ this.sp = allocated
        last-task!                           \ last-task = this
    does> ;

: task-choose-next ( -- )    
    current-task
    begin        
        .next @ dup
        .status @ PAUSED =
    until ;

: task-save-context ( sp ip rp -- ) \ XXX temporal coupling
    current-task .rp !
    current-task .ip !
    current-task .sp ! ;

: task-restore-context ( -- )    
    current-task .sp @ sp!
    current-task .rp @ rp!
    current-task .ip @ >r ;

: task-run ( task -- )
    current-task!
    SKIPPED current-task .status !
    task-restore-context ;

: pause-multi ( -- )
    PAUSED current-task .status !
    sp@ r> rp@ task-save-context
    task-choose-next task-run ;

: pause-single ( -- ) ;

: pause ( -- )
    var-xt-pause @ execute ;

: activate ( task -- )
    r> over .ip !
    PAUSED current-task .status !   \ pause current task
    sp@ cell + r> rp@ task-save-context        
    task-run ;

: stop ( task -- )
    SKIPPED swap .status ! 
    task-choose-next task-run ;

: deactivate ( -- )
    current-task stop ;

: semaphore: ( -- ) variable! ;
: mutex: ( -- ) 1 semaphore: ;

: wait ( semaphore -- )
    begin
        pause
        dup @ 0<>
    until
    -1 swap +! ;

: signal ( semaphore -- )
    1 swap +! 
    pause ;
 
: multi ( -- ) \ switch to multi-task mode
    ['] pause xpause !
    ['] pause-multi var-xt-pause ! ;

: single ( -- ) \ switch to signle-task mode
    0 xpause ! 
    ['] pause-single var-xt-pause ! ;

: mailbox: ( size ) ( -- mailbox ) ringbuffer: ;

: send ( element mailbox -- )
    begin
        dup full? 
    while
        pause 
    repeat
    enqueue ;

: receive ( mailbox -- element )
    begin
        dup empty?
    while
        pause
    repeat
    dequeue ;