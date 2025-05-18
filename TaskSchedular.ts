// @author: 321_Closet
/*
   @description: a multi-use schedular class to create task objects and schedule execution of threads and functions
   in translation units
*/

const HttpService = game.GetService("HttpService");

export class ScheduleParams {
   public PARAMS: number[] = []
   constructor(repeat: number, wait: number) {
      assert(repeat, "Attempt to create object schedule params with argument 1 missing or null");
      assert(wait, "Attempt to create object schedule params with argument 2 missing or null")
      this.PARAMS.insert(0, repeat); // n times to repeat
      this.PARAMS.insert(1, wait); // n times to wait before repeating
   }
}


export class c_TaskSchedular {
   private schedule: any = {};
   private RunLoop: any;
   private ExecutionYield: number = 2;
   private ThreadCache: any = {};
   constructor() {
      return this;
   }

   /**
    * @method Start: have the schedular object begin executing every single task withit its list
    */
   public Start() {
       const self = this;
      this.RunLoop = coroutine.create(function(){
         while (true) {
            task.wait(self.ExecutionYield)
            for (const key in self.schedule) {
               if (type(self.schedule[key].run) ===  "thread") 
               {
                  coroutine.resume(self.schedule[key].run, self.schedule[key].params);
                  if (self.schedule[key]) {
                    delete self.schedule[key];
                  }
               } else if (type(self.schedule[key].run) === "function") 
               {
                  self.schedule[key].run(self.schedule[key].params);
                  if (self.schedule[key]) {
                     delete self.schedule[key];
                  }
               }
            }
         }
      }); 
   } 

   /**
    * @method ModifyYield: change the yield of the RunLoop causing execution of a task to occur after n time has elapsed
    */
   public ModifyYield(n: number) {
      this.ExecutionYield = n;
   } 

   /**
    * @method ScheduleThread: add a thread to the schedulars object list of tasks
    */
   public ScheduleThread(params: any[], ScheduleParams: ScheduleParams, co: thread) {
      const recurse = ScheduleParams.PARAMS[0];
       if (recurse > 0) {
         const elapse= ScheduleParams.PARAMS[1];

         for (let i =0; i <= recurse; i++) {
            task.wait(elapse);
            coroutine.resume(co, params);
         }
       } else if (this.RunLoop) {
         this.schedule[HttpService.GenerateGUID(false)] = {params : params, run : co};
       }
   }

   /**
    * @method ScheduleFunction: add a function to the schedulars object list of tasks
    * Note: functions are given parameters as tables of given values, scheduled functions should
    * ensure to read the values from the given hashmaps correctly, parameters supplied for scheduled functions
    * must be in a hash format with key-value pairs for indexing
    * Example(luau): local function(parameters: {}) 
    *    print(parameters.Name)
    * end
    */
   public ScheduleFunction(params: any[], ScheduleParams: ScheduleParams, fn: (params: any[])=>any) {
      assert(ScheduleParams, "Attempt to call function ScheduleFunction with missing argument #2")
      assert(fn, "Attempt to call function ScheduleFunction with missing argument #3")
      const recurse = ScheduleParams.PARAMS[0];
      if (recurse > 0) {
         const elapse= ScheduleParams.PARAMS[1];
        let co = coroutine.wrap(function(): any[]{
            let results: any[] = [];
            let offset = 0;
            for (let i = 0; i <= recurse; i++) {
               task.wait(elapse)
               const result = fn(params);
               results.insert(offset, result);
               offset += 1;
            }

            return results;
         })

         return co();
      } else if (this.RunLoop) {
         this.schedule[HttpService.GenerateGUID(false)] = {params : params, run : fn};
      }
   }

   /**
    * @method Spawn: run a function or thread immediately through the schedular
    */
   public Spawn(f: ()=>void | thread) {
      task.spawn(f);
   }

   /**
    * @method SpawnAfter: run a function or thread immediately through the schedular after n has elapsed
    */
   public SpawnAfter(wait: number, f: ()=>void | thread) {
      task.delay(wait, function() {
         task.spawn(f);
      })
   }

   /**
    * @method CreateThread: returns a thread id of a new thread
    */
   public CreateThread(callback: ()=>any): string {
      const threadId = HttpService.GenerateGUID(false);
      let co = coroutine.create(callback);
      this.ThreadCache[threadId] = co;
      return threadId;
   }

   /**
    * @method ResumeThread: resumes a thread from the given thread id
    * @args: A mutable list of any
    */
   public ResumeThread(threadId: string, args: any[] | {}): void {
      assert(threadId, "Attempt to resume thread with argument #1 missing or nil")
      let co = this.ThreadCache[threadId];
      assert(co, "Unable to find thread from id")

      coroutine.resume(co, args);
      delete this.schedule[threadId];
   }

   /**
    * @method CancelThread: cancels the thread of given thread id
    */
   public CancelThread(threadId: string) {
      assert(this.ThreadCache[threadId], "Attempt to cancel non-existant thread");
      let co: thread = this.ThreadCache[threadId];
      coroutine.yield(co);
      coroutine.close(co);
   }

   /**
    * @method PauseThread: Pauses the given thread from threadId until x has elapsed
    */
   public PauseThread(x: number, threadId: string) {
      let co: thread = this.ThreadCache[threadId];
      assert(co, "Attempt to pause non-existant thread");
      coroutine.yield(co)

      task.delay(x, function(){
         coroutine.resume(co);
      })
   }
}

declare module "C:/berry/src/TaskSchedular";
