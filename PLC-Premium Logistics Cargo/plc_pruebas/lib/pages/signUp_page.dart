import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plc_pruebas/services/firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String nombre = '';
  String apellido = '';
  String numeroIdentidad = '';
  String email = '';
  String telefono = '';
  String direccion = '';
  String departamento = '';
  String municipio = '';
  String password = '';
  String confirmPassword = '';
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final List<String> departamentos = [
    'Atlántida',
    'Choluteca',
    'Colón',
    'Comayagua',
    'Copán',
    'Cortés',
    'El Paraíso',
    'Francisco Morazán',
    'Gracias a Dios',
    'Intibucá',
    'Islas de la Bahía',
    'La Paz',
    'Lempira',
    'Ocotepeque',
    'Olancho',
    'Santa Bárbara',
    'Valle',
    'Yoro'
  ];

  final Map<String, List<String>> municipios = {
    'Atlántida': [
      'La Ceiba',
      'El Porvenir',
      'Esparta',
      'Jutiapa',
      'La Masica',
      'San Francisco',
      'Tela',
      'Arizona'
    ],
    'Colón': [
      'Trujillo',
      'Balfate',
      'Iriona',
      'Limón',
      'Sabá',
      'Santa Fe',
      'Santa Rosa de Aguán',
      'Sonaguera'
    ],
    'Comayagua': [
      'Comayagua',
      'Ajuterique',
      'El Rosario',
      'Esquías',
      'Humuya',
      'La Libertad',
      'Lamaní',
      'La Trinidad',
      'Lejamaní',
      'Meámbar',
      'Minas de Oro',
      'Ojos de Agua',
      'San Jerónimo',
      'San José de Comayagua',
      'San Sebastián',
      'Siguatepeque',
      'Villa de San Antonio'
    ],
    'Copán': [
      'Santa Rosa de Copán',
      'Cabañas',
      'Concepción',
      'Copán Ruinas',
      'Corquín',
      'Cucuyagua',
      'Dolores',
      'Dulce Nombre',
      'El Paraíso',
      'La Unión',
      'Nueva Arcadia',
      'San Agustín',
      'San Antonio',
      'San Jerónimo',
      'San José',
      'San Juan de Copán',
      'San Nicolás',
      'San Pedro',
      'Santa Rita',
      'Trinidad de Copán',
      'Veracruz'
    ],
    'Cortés': [
      'San Pedro Sula',
      'Choloma',
      'Omoa',
      'Pimienta',
      'Potrerillos',
      'Puerto Cortés',
      'San Antonio de Cortés',
      'San Francisco de Yojoa',
      'San Manuel',
      'Santa Cruz de Yojoa',
      'Villanueva',
      'La Lima'
    ],
    'Choluteca': [
      'Choluteca',
      'Apacilagua',
      'Concepción de María',
      'Duyure',
      'El Corpus',
      'El Triunfo',
      'Marcovia',
      'Namasigüe',
      'Pespire',
      'San Antonio de Flores',
      'San Isidro',
      'San José',
      'San Marcos de Colón',
      'Santa Ana',
      'Orocuina',
      'Pespire'
    ],
    'El Paraíso': [
      'Yuscarán',
      'Alauca',
      'Danlí',
      'El Paraíso',
      'Güinope',
      'Jacaleapa',
      'Liure',
      'Morocelí',
      'Oropolí',
      'Potrerillos',
      'San Antonio de Flores',
      'San Lucas',
      'Teupasenti',
      'Texiguat'
    ],
    'Francisco Morazán': [
      'Distrito Central (Tegucigalpa y Comayagüela)',
      'Alubarén',
      'Cedros',
      'Curarén',
      'El Hatillo',
      'Guaimaca',
      'La Libertad',
      'Lepaterique',
      'Maraita',
      'Marale',
      'Nueva Armenia',
      'Ojojona',
      'Orica',
      'Reitoca',
      'Sabanagrande',
      'San Antonio de Oriente',
      'San Buenaventura',
      'San Ignacio',
      'San Juan de Flores',
      'San Miguelito',
      'Santa Ana',
      'Santa Lucía',
      'Talanga',
      'Tatumbla',
      'Valle de Ángeles',
      'Villa de San Francisco'
    ],
    'Gracias a Dios': [
      'Puerto Lempira',
      'Brus Laguna',
      'Juan Francisco Bulnes',
      'Ramón Villeda Morales',
      'Wampusirpi',
      'Ahuas'
    ],
    'Intibucá': [
      'La Esperanza',
      'Camasca',
      'Colomoncagua',
      'Concepción',
      'Dolores',
      'Intibucá',
      'Jesús de Otoro',
      'San Antonio',
      'San Francisco de Opalaca',
      'San Isidro',
      'San Juan',
      'San Marcos de la Sierra',
      'San Miguel Guancapla',
      'Santa Lucía',
      'Yamaranguila',
      'Magdalena'
    ],
    'Islas de la Bahía': [
      'Roatán',
      'Guanaja',
      'José Santos Guardiola',
      'Utila'
    ],
    'La Paz': [
      'La Paz',
      'Aguanqueterique',
      'Cabañas',
      'Cane',
      'Chinacla',
      'Guajiquiro',
      'Lauterique',
      'Marcala',
      'Mercedes de Oriente',
      'Opatoro',
      'San Antonio del Norte',
      'San José',
      'San Juan',
      'San Pedro de Tutule',
      'Santa Ana',
      'Santa Elena',
      'Santa María',
      'Santiago de Puringla',
      'Yarula'
    ],
    'Lempira': [
      'Gracias',
      'Belén',
      'Candelaria',
      'Cololaca',
      'Erandique',
      'Gualcince',
      'Guarita',
      'La Campa',
      'La Iguala',
      'Las Flores',
      'La Unión',
      'Mapulaca',
      'Piraera',
      'San Andrés',
      'San Francisco',
      'San Juan Guarita',
      'San Manuel Colohete',
      'San Marcos de Caiquín',
      'San Rafael',
      'San Sebastián',
      'Santa Cruz',
      'Talgua',
      'Tomalá',
      'Valladolid',
      'Virginia'
    ],
    'Ocotepeque': [
      'Ocotepeque',
      'Belén Gualcho',
      'Concepción',
      'Dolores Merendon',
      'Fraternidad',
      'La Encarnación',
      'La Labor',
      'Lucerna',
      'Mercedes',
      'San Fernando',
      'San Francisco del Valle',
      'San Jorge',
      'San Marcos',
      'Santa Fe',
      'Sinuapa',
      'Sensenti'
    ],
    'Olancho': [
      'Juticalpa',
      'Campamento',
      'Catacamas',
      'Concordia',
      'Dulce Nombre de Culmí',
      'El Rosario',
      'Esquipulas del Norte',
      'Gualaco',
      'Guarizama',
      'Guata',
      'Guayape',
      'Jano',
      'La Unión',
      'Mangulile',
      'Manto',
      'Salamá',
      'San Esteban',
      'San Francisco de la Paz',
      'San Juan',
      'San Lorenzo',
      'Santa María del Real',
      'Silca',
      'Yocón'
    ],
    'Santa Bárbara': [
      'Santa Bárbara',
      'Arada',
      'Atima',
      'Azacualpa',
      'Ceguaca',
      'Chinda',
      'Concepción del Norte',
      'Concepción del Sur',
      'El Níspero',
      'Gualala',
      'Ilama',
      'Macuelizo',
      'Naranjito',
      'Nueva Celilac',
      'Petoa',
      'Protección',
      'Quimistán',
      'San Francisco de Ojuera',
      'San José de Colinas',
      'Las Vegas',
      'San Luis',
      'San Marcos',
      'San Nicolás',
      'San Pedro Zacapa',
      'Santa Rita',
      'Trinidad'
    ],
    'Valle': [
      'Nacaome',
      'Alianza',
      'Amapala',
      'Aramecina',
      'Caridad',
      'Goascorán',
      'Langue',
      'San Francisco de Coray',
      'San Lorenzo'
    ],
    'Yoro': [
      'Yoro',
      'Arenal',
      'El Negrito',
      'El Progreso',
      'Jocón',
      'Morazán',
      'Olanchito',
      'Santa Rita',
      'Sulaco',
      'Victoria',
      'Yorito'
    ],
  };

  List<String> _municipiosDisponibles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Cliente'),
        backgroundColor: Colors.orange.shade700, // Orange aesthetic for header
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade700, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su nombre';
                  } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                    return 'El nombre no puede contener números ni caracteres especiales';
                  }
                  return null;
                },
                onSaved: (value) => nombre = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Apellido'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su apellido';
                  } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                    return 'El apellido no puede contener números ni caracteres especiales';
                  }
                  return null;
                },
                onSaved: (value) => apellido = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Número de Identidad'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su número de identidad';
                  } else if (!RegExp(r'^\d{4}-\d{4}-\d{5}$').hasMatch(value)) {
                    return 'El número de identidad debe tener el formato 0000-0000-00000 y solo contener números';
                  }
                  return null;
                },
                onSaved: (value) => numeroIdentidad = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Por favor ingrese un email válido';
                  }
                  return null;
                },
                onSaved: (value) => email = value!,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_passwordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su contraseña';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    password = value;
                  });
                },
                onSaved: (value) => password = value!,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Confirme su contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_confirmPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor confirme su contraseña';
                  } else if (value != password) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    confirmPassword = value;
                  });
                },
                onSaved: (value) => confirmPassword = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Teléfono'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su número de teléfono';
                  } else if (!RegExp(r'^[389]\d{3}-\d{4}$').hasMatch(value)) {
                    return 'El número de teléfono debe tener el formato 0000-0000 y empezar con 9, 8 o 3';
                  }
                  return null;
                },
                onSaved: (value) => telefono = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Dirección'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su dirección';
                  }
                  return null;
                },
                onSaved: (value) => direccion = value!,
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Departamento'),
                items: departamentos.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    departamento = newValue!;
                    municipio = ''; // Reset municipio when departamento changes
                    _municipiosDisponibles = municipios[departamento] ?? [];
                  });
                },
                onSaved: (value) => departamento = value!,
              ),
              if (_municipiosDisponibles.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Municipio'),
                  value: municipio.isNotEmpty ? municipio : null,
                  items: _municipiosDisponibles.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      municipio = newValue!;
                    });
                  },
                  onSaved: (value) => municipio = value!,
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Updated button color
                  foregroundColor: Colors.white,
                ),
                child: Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Las contraseñas no coinciden')),
        );
        return;
      }
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _firestoreService.addCliente(
          nombre,
          apellido,
          numeroIdentidad,
          email,
          telefono,
          direccion,
          municipio, // Save municipio as cuidad
          departamento,
          'Honduras',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente registrado exitosamente')),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'email-already-in-use') {
          errorMessage = 'El correo electrónico ya está en uso.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'La contraseña es demasiado débil.';
        } else {
          errorMessage = 'Error al registrar cliente: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }
}
