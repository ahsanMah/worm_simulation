import csv

data = open("simulationPHSim4.2.csv", "rb")
data_reader = csv.reader(data)

total_pop = 0
i = 0
monitor_num = 1
current_pop = 0

while i < 8851:
        data_reader.next()
        i += 1
        
print data_reader.next()
sim_num = 1
data_list = []
max_pop = []

for i in range(4):
        max_pop.append(0)

for row in data_reader:
	data_list.append(row)

while monitor_num < 5:
	current_pop = int(data_reader.next()[3])
	max_pop[monitor_num - 1] += current_pop
	monitor_num += 1
monitor_num = 1
print "End of file"

# # print len(max_pop)
# print max_pop
# print type(data_reader.next()[3])
# while not end:
# 	pass
# 	# while sim_num < 9:
#  	current_pop = int(row[3])
# 	# 	print sim_num - 1
# 	# 	if (max_pop[sim_num - 1] < int (current_pop)): 
# 	# 		max_pop = current_pop
# 	# 	sim_num += 1
# 	# sim_num = 1
# 	print current_pop
# 	if max_pop < current_pop:
# 		max_pop = current_pop



print max_pop
                
 #density = total_pop / 354

# print density
