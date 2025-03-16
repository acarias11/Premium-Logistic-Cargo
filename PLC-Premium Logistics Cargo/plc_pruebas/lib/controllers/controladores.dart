import 'package:flutter/material.dart';

class ControladoresCarga {
  // Controllers for TextFields
  final TextEditingController entrega_inicialController = TextEditingController();
  final TextEditingController entrega_finalController = TextEditingController();
  final TextEditingController estatusIDController = TextEditingController();
  final TextEditingController fecha_inicialController = TextEditingController();
  final TextEditingController fecha_finalController = TextEditingController();
  final TextEditingController modalidadController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController piezasController = TextEditingController();
}

class ControladorClientes {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController numero_identidadController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController ciudadController = TextEditingController();
  final TextEditingController departamentoController = TextEditingController();
  final TextEditingController paisController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
}

class ControladorPaquetes {
  final TextEditingController traking_numberController = TextEditingController();
  final TextEditingController warehouseIDController = TextEditingController();
  final TextEditingController estatusIDController = TextEditingController();
  final TextEditingController tipoController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController modalidadController = TextEditingController();

  void clearControllers() {}
}

class ControladorWarehouse {
  final TextEditingController cargaIDController = TextEditingController();
  final TextEditingController clienteIDController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController estatusIDController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController modalidadController = TextEditingController();
  final TextEditingController peso_totalController = TextEditingController();
  final TextEditingController piezasController = TextEditingController();
}