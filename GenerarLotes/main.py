import scripts.GeneracionClientes as GC
import scripts.GeneracionEmpleados as GE
import scripts.GeneracionFacturas as GF
import sys


# Obtener valores pasados por argumento o usar valores por defecto
clientes_cant = int(sys.argv[1]) if len(sys.argv) > 1 else 200
empleados_cant = int(sys.argv[2]) if len(sys.argv) > 2 else 50
facturas_cant = int(sys.argv[3]) if len(sys.argv) > 3 else 5000

GC.generar_clientes(clientes_cant)
GE.generar_empleados(empleados_cant)
GF.generar_facturas(facturas_cant)