import csv

def calc_annual_avg (population):
	return population/365

data = open("simulationPHSim4.2.csv", "rb")
data_reader = csv.reader(data)

total_pop = 0
i = 0
monitor_num = 0
current_pop = 0
index = 0

while i < 8550:
        data_reader.next()
        i += 1
        
print data_reader.next()
sim_num = 1
data_list = []
max_pop = []
avg_pop = []

for i in range(4):
        max_pop.append(0)

for row in data_reader:
	data_list.append(row)

for row in data_list:
	index = (monitor_num % 4)
	current_pop = int(row[3])
	max_pop[index] += current_pop
	monitor_num += 1


print max_pop
avg_pop = map(calc_annual_avg, max_pop)
print avg_pop