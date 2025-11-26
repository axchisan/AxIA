class ChatCommandParser {
  static const List<String> commands = [
    '/rutina',
    '/recordar',
    '/agenda',
    '/nota',
    '/proyecto',
    '/presencia',
    '/ayuda',
  ];

  static String? parseCommand(String message) {
    for (final command in commands) {
      if (message.startsWith(command)) {
        return command;
      }
    }
    return null;
  }

  static String getCommandResponse(String command, String input) {
    switch (command) {
      case '/rutina':
        return 'Voy a agregar una nueva rutina para ti.';
      case '/recordar':
        return 'Anotaré este recordatorio.';
      case '/agenda':
        return 'Verificando tu agenda...';
      case '/nota':
        return 'Guardando nota privada...';
      case '/proyecto':
        return 'Consultando tus proyectos...';
      case '/presencia':
        return 'Cambiando tu estado de presencia...';
      case '/ayuda':
        return 'Estos son los comandos disponibles:\n/rutina - Agregar rutina\n/recordar - Crear recordatorio\n/agenda - Ver agenda\n/nota - Guardar nota\n/proyecto - Gestionar proyecto\n/presencia - Cambiar estado';
      default:
        return 'Comando no reconocido.';
    }
  }
}
