import csv

def calc_annual_avg (population):
	return population/365

def getAvgPop (data_list, max_pop):
	monitor_num = 0
	# map (lambda x: float(x), current_row)
	avg_pop = []

	for row in data_list:
		index = (monitor_num % 4)
		current_pop = int(row[3])
		max_pop[index] += current_pop
		monitor_num += 1


	print max_pop
	# avg_pop = map(lambda pop: pop/365, max_pop)
	avg_pop = map(calc_annual_avg, max_pop)
	return avg_pop


data = open("simulationPHSim4.2.csv", "rb")
data_reader = csv.reader(data)

while int(current_row[0]) != 121:
	curr_data_list.append(current_row)
	current_row = data_reader.next()



print getAvgPop(curr_data_list, pop_list)

curr_data_list = []
total_pop = 0
i = 0
current_pop = 0
index = 0

# while i < 8550:
#         data_reader.next()
#         i += 1
current_row = data_reader.next()

while int(current_row[0]) != 342:
	current_row = data_reader.next()

for row in data_reader:
	

pop_list = [int(current_row[3]),0,0,0]




