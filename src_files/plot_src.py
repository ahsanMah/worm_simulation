import csv
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import colors

fig,sub = plt.subplots()

def convert_to_float (item):
        if item != '':
                return float(item)
        return None

def add(num, inc):
        return num + inc

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

def curve_fit(xvals,yvals):
        points = np.linspace(-0.3,0.5,100)
        curve = np.poly1d(np.polyfit(xvals,yvals10yr,2))
        plt.plot(xvals,yvals,"bo",points,curve(points),"-g")

        plt.ylabel('Max Pop in Year 10')
        plt.xlabel("pH Tolerance")
        plt.show()
        return

def make_labels (val):
        if (val > 0): 
                return "+" + str(val)
        return str(val)


def getFromBS (data_reader):
        data = open("test.csv", "rb")
        data_reader = csv.reader(data)
        data_table = []
        xvals = []              #values to be plotted on the x-axis
        yvals = []              #values to be plotted on the y-axis
        run_data = []   #data for individual runs
        current_row = data_reader.next()
        while current_row[0] != "ph_tolerance":
                var = data_reader.next()
                if len(var) > 0:
                        current_row = var

        xvals = map(convert_to_float, current_row[1:]) #str to float
        xvals = np.array(xvals)                            #list to array
        xlabels = map(make_labels,xvals)

        print xvals


        while current_row[0] != "[initial & final values]":     
                var = data_reader.next()
                if len(var) > 0:
                        current_row = var

        for row in data_reader:
                data_table.append(row)

        for row in data_table:
                for val in row:
                        if len(val) > 0:
                                run_data = val.split()
                                run_data[0] = run_data[0][1:]
                                run_data[-1] = run_data[-1][:-1]
                                yvals.append(map(convert_to_float, run_data))
                        run_data = []

        # print yvals
        # print yvals5yr
        # print yvals10yr

        # curve_fit(xvals,yvals10yr)
        #draw_hist(xlabels,yvals)
        return


'''
Draws a histogram with the given data

parameters -> (x-axis labels, heights of the bars)

'''
def draw_hist_err (xlabels, yvals, err_list, legend):
        
        xvals = np.arange(len(xlabels))
        width = 0.9/len(yvals)
        x_width = 0
        plt.yscale('symlog')
        sub.set_xticks(xvals + 0.5)
        sub.set_xticklabels(xlabels)
        plt.xlabel("Region Number")
        plt.ylabel("Density in Region")
        colors = ['g','c','m','r','y','b','k']

        for idx in range(len(legend)): #for every parameter value
                mon_list = yvals[idx]
                std_err = err_list[idx]
                clr = colors[idx]
        
                plt.bar(xvals + x_width,mon_list,width, color = clr, yerr = std_err, label = legend[idx])
                x_width += width

        return



'''
Parses the file and returns a list of the max densities of the data file given

(filename) --> average population, standard errors, x-axis labels
'''
def extractFromFile (filename, reps):
        data = open(filename, "rb")
        data_reader = csv.reader(data)
        data_table = {} #temporary table that stores info from files
        xvals = []              #values to be plotted on the x-axis
        yvals = []              #values to be plotted on the y-axis
        run_data = []   #data for individual runs
        row = []
        multi_run = []
        data_reader.next() #skips the header line
        for i in range(reps):
                yvals = []
                row = data_reader.next()
                data_table = {}
        
                while row[0] != "END SIM":

                        monitor_num = row[1]
                        monitor_pop = convert_to_float(row[3])
                        if data_table.has_key(monitor_num):
                                if data_table[monitor_num][2] < monitor_pop:
                                        data_table[monitor_num] = map(convert_to_float,row[2:]) #data from
                        else:                                                                   #species number onward
                                data_table[monitor_num] = map(convert_to_float,row[2:])         #is stored

                        row = data_reader.next()

                for key in sorted(data_table.keys()):
                        yvals.append (data_table[key][2])        
                
                multi_run.append(yvals)

        if reps > 1:
                avg_pop = np.mean(multi_run, axis = 0)
                std_err = np.std(multi_run, axis = 0) / np.sqrt(reps)        
        else:
                avg_pop = multi_run[0]
                std_err = [0]*len(avg_pop) #creates an array of 0s

        xlabels = sorted(data_table.keys())

        # for idx,val in enumerate(avg_pop):
        #         print xlabels[idx],val,std_err[idx]

        return avg_pop, std_err, xlabels

def getFileName(folder_name,param, val):
        std_name = list("0_0_0_0")
        std_name[param] = str(val)             #changes the parameter value at the correct position  
        if val == 0 : std_name[param] = str(0) #since Netlogo appends '0' to files instead of '0.0'
        file_pathway = "simulations/" + folder_name + "/output/" + "".join(std_name) + ".csv"
        
        return file_pathway


def getPlotVals(usr_input):
        densities = []
        err_list = []
        mon_list = []
        param_pos = {"Temperature": 0, "pH": 2, "Genetic Diversity": 4, "Frequency of random insertions": 6, "Number of Roads": 8}

        folder_name = usr_input[0]
        param = usr_input[1]
        idx = param_pos[param]
        param_val = usr_input[2]
        inc = usr_input[3]
        final = usr_input[4]
        reps= usr_input[5]

        param_list = []

        while param_val <= final:
                param_list += [param_val]
                sim_name = getFileName(folder_name, idx, param_val)
                yval,err,xlabels = extractFromFile(sim_name,reps)
                densities.append(yval)
                err_list.append(err)
                param_val += inc

        return densities,err_list,xlabels, param_list


def askUser(param_ids):
        save_name = raw_input("Enter the name of the simulation as seen in NetLogo: ")
        print ("1. Temperature\n2. pH\n3. Genetic Diversity\n4. Frequency of random insertions\n5. Number of Roads")
        idx = int(raw_input("Select the parameter that was varied: "))
        param = param_ids[idx]
        start = float(raw_input("Value of starting parameter: "))
        inc = float(raw_input("Increment: "))
        final = float(raw_input("Value of stopping parameter: "))
        rep = int(raw_input("Repetitions per simulation: "))
        return [save_name,param,start,inc,final,rep]


def plotBar(params,pos):
        densities = []
        err_list = []
        mon_list = []
        param_ids = {1: "Temperature", 2: "pH", 3: "Genetic Diversity", 4: "Frequency of random insertions", 5: "Number of Roads"}
        
        plt.subplot(1,2,pos)
        usr_input = params[:2] + map(convert_to_float,params[2:5]) + [int(params[-1])]
        print usr_input
        densities,err_list,mon_list,legend = getPlotVals(usr_input)
        draw_hist_err(mon_list,densities,err_list, legend)
        plt.title(usr_input[1] + " Tolerance")
        legend = plt.legend(loc='best', shadow=True, fontsize='medium', title = usr_input[1] + " Levels")



# usr_input = askUser(param_ids)
# print usr_input

pos = 0
sim_params = csv.reader(open("simParams.csv","rU"))
sim_params.next()

for param in sim_params:
        pos += 1
        plotBar(param,pos)


plt.show()
