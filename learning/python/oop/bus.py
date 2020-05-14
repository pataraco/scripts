from vehicle import Vehicle


class Bus(Vehicle):
    def __init__(self, max_speed=100):  # Constructor
        super().__init__(max_speed)
        self.passengers = []

    def add_passengers(self, passengers):
        self.passengers.extend(passengers)


bus1 = Bus()
bus2 = Bus(75)
bus1.warnings.append("high temp")
print(bus1.__dict__)
print(bus2.__dict__)
print(f"vehicle mileage (private): {bus2._Vehicle__mileage}")
print(bus1)
bus2.increase_mileage(2000)
print(f"mileage: {bus2.get_mileage()}")
bus1.drive()
