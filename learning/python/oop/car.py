from vehicle import Vehicle


class Car(Vehicle):
    def brag(self):
        print(f"My car is awesome!")


car1 = Car()
car2 = Car(200)
car1.warnings.append("low oil")
print(car1.__dict__)
print(car2.__dict__)
print(car1)
car2.increase_mileage(1000)
print(f"mileage: {car2.get_mileage()}")
car1.brag()
