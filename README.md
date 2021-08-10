# Simulator_of_Queues_in_a_Restaurant

This is a simulation experiment of clients waiting in 2 successive queues. This experiment is meant to teach us how to estimate the statistics of satisfied/unsatisfied customers in a certain amount of time and how these statistics might change if we make changes to the circumstances.

The app is made in R, with the interface made with shinyapp.

Supposedly the events take place in a restaurant, which is open every day of the week between 9:00 am and 9:00 pm. The first queue is meant for placing orders and paying, and the second queue - for picking up the food. The maximum amount of people waiting in the first queue is 10, and in the second queue - 15. We count the people who come after the number is reached as unsatisfied customers. 

After 9:00 pm, no customers are allowed, but the ones already waiting in the queue will be served. 

The rush hours are 1:00 - 2:30 pm and 7:00 - 8:00 pm. 

We have implemented a function (called "genereaza_Ts") that receives the current time and generates randomly the time of the next client's appearance, which will always be greater than the current time. The variable for keeping in check with the time is 0 at 9 am and 12 at 9 pm. This function generates smaller time between each arrival during rush hours, so that more clients come during rush hours.

We also have implemented functions that will return the time of waiting in each line for every client (minus the amount of time one has to wait because of other clients who came before them). The first function, for the first line (called "genereaza_Y1") returns a value of 0.5 with the probability of 1/4, of 0.8 with the probability of 1/2 and so on. The second function (called "Norm) returns a random number of normal distribution of mean 15 and variance 2. Instead of using a convenient R function for random numbers of normal distribution, we used a mathematical algorithm that calculates this number based on a number of standard uniform distribution. The mathematical thinking and the process of finding the formula is in the paper. 

We also have decided upon a function (called "pret") that will give us the prices for the food consumed by each satisfied client. The function receives the amount of time (t) a client has to wait in the second line (the time needed for food to be prepared). The food for each client is prepared successively, not at the same time. The function returns a value equal to 5t^2 +  90t (t is always a very small number between 0 and 1). 

The main function is called "schema_simulare" and it moves in time to whichever event is closer: the arrival of a new client, the moment a client leaves the first line, or the moment a client leaves the system (the second line). The data of times of arrival, amount of time spent in each line, amount of money made, amount of satisfied and unsatisfied clients per each hour of the day and time of leaving is stored in different arrays for us to be able to make statistical graphs.

We also have counducted the experiment in which case the schedule of the restaurant starts one hour earlier, also in which case the schedule is increased by an hour later. 
Another experiment was seeing by how much will the income be increased if the maximum amount of people waiting for each line is increased by 5. 


The mean results we got, for 1000 experiments:

The minimal time of waiting in the first line: 0.00833 hours

The minimal time of waiting in the second line: 0.20602 hours

The minimal time of waiting in the system: 0.21435 hours


The maximal time of waiting in the first line: 1.139847 hours

The maximal time of waiting in the second line: 3.73911 hours

The maximal time of waiting in the system: 4.829137 hours


The mean time of waiting in the 1st line: 0.1164337 hours

The mean time of waiting in the 2nd line: 2.896499 hours

The mean time of waiting in the system: 3.012932 hours








