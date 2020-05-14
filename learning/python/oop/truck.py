from vehicle import Vehicle


class Truck(Vehicle):
    no_of_wheels = 6

    def set_load(self, load):
        if load > 0:
            self.__load = load


truck1 = Truck()
truck2 = Truck(200)
truck1.warnings.append("low oil")
print(truck2.__dict__)
print(truck1)
truck2.increase_mileage(1000)
print(truck2.get_mileage())
