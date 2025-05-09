# 2-List_virtual_Queue
Created a LinkedList Fifo which are mostly used for virtual queueing. In this case, I have 2 list ; List A and List B
Its a ready valid fifo and each fifo entry is pushed based on the wdata[DATAWIDTH] bit. Similarly the pop entry is based on the rd_list signal.
For a virtual Fifo, you need 2 memory instances. One is for storing Data (SRAM) and other is for storing the back to back write indexes for that particular List (SRAM list memory).
In here for ex: we have 2 list : List A and List B
Pseudo Code as Below for the SRAM List Memory (list memory basically links all your nodes together)
If wdata[DATAWIDTH] is 1, List A will be queued. Ohterwise List B.
wr_idx is a pointer which tells us the index of the sram where the wdata will be stored. As this is the 1st psuh entry for List A, we  keep both Head and Tail Pointer values as wr_idx.
However, when a new wr_idx comes in and there is a push entry for List A, we update the tail pointer for the List to wr_idx. For the SRAM list memory , we now link the old index address and store the 
new wr_idx to the old index. for ex: wr_idx =6 and its the 1st entry for List A, waddr of SRAM memory will be 0x6, and wdata will be XX. In the 2nd entry, when New wr_idx = 0x20 the waddr of the 
SRAM list memory will 0x6 and wdata will be 0x20. So in the next one, 0x20 will be the address and new wr_idx will be the wdata. This keeps going on until my counter for list A is exhausted.
This is similar for List B
For read, we have rd_list which decides to pop List A or List B. Now Head ptr is updated to the next addr (in this case wdata from the SRAM list mem) till my counter value comes to 0 and the index(waddr) 
points to NULL. IN the above case, lets assume there are only 2 writes which means that Head pointer is pointed to 0x6. Now 2 back to back pop happens, Head pointer as indexed as 0x6 will fetch the wdata
(in this case 0x20) and will get updated to 0x20 and the counter will decrement. Another pop will basically make Head and tail pointer both xx and as 0x20 address doesnt contain any wdata, it will tell us
that it was the last data to be popped and List B is empty now.
