# CanelaKeychain para iOS - Funciones que nos permitirá trabajar mas fácil

Esta es una colección de funciones auxiliares para guardar texto y datos en el KeyChain. Como probablemente hayas notado, la API de KeyChaon de Apple es muy poco detallada. 

Esta librería fue diseñada para proporcionar una sintaxis más corta para realizar una tarea simple: leer / escribir valores de texto para claves específicas:

~~~
let keychain = CanelakeyChain()
if let textDes = myTextFieldTF.text 
    keychain.setValueString(textDes, forKey: Utils().KeychainDemo_keyName)
}
~~~

La librería de CanelaKeyChain incluye las siguientes características:

- Obtener, configurar y eliminar elementos de cadena, booleanos y llaveros de datos
- Especificar el nivel de seguridad de acceso al elemento

## ¿Qué es KeyChain?

El KeyChain es un almacenamiento seguro. Puede almacenar todo tipo de datos confidenciales en él: contraseñas de usuario, números de tarjetas de crédito, tokens secretos, etc. Una vez almacenada en Keychain, esta información solo está disponible para su aplicación, otras aplicaciones no pueden verla. Además de eso, el sistema operativo se asegura de que esta información se mantenga y procese de forma segura. Por ejemplo, el texto almacenado en Keychain no se puede extraer de la copia de seguridad del iPhone o de su sistema de archivos. Apple recomienda almacenar solo una pequeña cantidad de datos en el llavero. Si necesita proteger algo grande, puede cifrarlo manualmente, guardarlo en un archivo y almacenar la clave en el llavero.

## Confiración y soporte

Configuración con Swift Package Manager
En Xcode 11+ seleccione Archivo> Paquetes> Agregar paquete de dependencias ... .
Ingrese la URL de este proyecto: https://github.com/phdafoe/CanelakeyChain.git

## Uso e implementación

Agregar en la cabecera del la clase `import CanelaKeyChain`
