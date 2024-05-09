import matplotlib.pyplot as plt
import sys

def plot_numbers_from_file(filename):
    # Read numbers from the file
    with open(filename, 'r') as file:
        numbers = [float(line.strip()) for line in file]

    # Plot the numbers
    plt.plot(numbers)
    plt.xlabel('Index')
    plt.ylabel('Value')
    plt.title('Plot of Numbers')
    plt.show()

# Example usage
filename = sys.argv[1]  # Change this to your file name
plot_numbers_from_file(filename)
