import csv

data = open("simulationpHSim4.2.csv", "rb")
data_reader = csv.reader(data)

total_pop = 0

for row in data_reader:
    total_pop += int (row[3])

density = total_pop / 354

print density
