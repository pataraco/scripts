# ### --- classes (begin) --- ###
class Vehicle(object):
    no_of_wheels = 4

    def __init__(self, max_speed=100):  # Constructor
        self.max_speed = max_speed
        self.warnings = []
        self.__mileage = 0  # private attribute

    def __repr__(self):  # General Output (wrapper)
        print("Printing...")
        return (
            f"Max Speed: {self.max_speed}, "
            + f"Number of Warnings: {len(self.warnings)}"
        )

    def increase_mileage(self, miles):
        if miles > 0:
            self.__mileage += miles

    def get_mileage(self):
        return self.__mileage

    def drive(self):
        print(f"Driving - max speed: {self.max_speed}")
