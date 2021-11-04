import 'package:flutter/material.dart';
import 'package:graphql_demoapp/screens/continents_screen.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// endpoint da nossa "API" graphQL
final String graphqlEndpoint = 'https://mz-graphql.hasura.app/v1/graphql';

// headers da nossa estrutura graphQL, com isto nós conseguimos ter acesso
//aos dados e schemas deste endpoint ()
final Map<String, String> myHasuraHeaders = {
  'content-type': 'application/json',
  'x-hasura-admin-secret':
      'cDFwt6CXzDtUfM6lJUfPEHvoWz3qXGILh3QD4zhevd99dx1B6M80NqmHjBH9bBCj'
};
void main() async {
  await initHiveForFlutter();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // criação de uma instancia do httpLink que vai permitir passar a
    // nossa simples URI String como um link [objecto] junto dos headers necessários
    final HttpLink httpLink =
        HttpLink(graphqlEndpoint, defaultHeaders: myHasuraHeaders);

    // para "assistir" às mudanças realizadas pelo GraphQL iremos usar o
    // ValueNotifier que permite guardar e monitorar mudanças de um valor.
    // No caso, vamos estar usando para o GraphQLCLient
    final ValueNotifier<GraphQLClient> client = ValueNotifier(
        //o GraphQL leva alguns parâmetros, e os mais importantes são:
        GraphQLClient(
      //o nosso link para aceder à API
      link: httpLink,
      // Implementação Cache do GraphQL, uma funcinalidade que torna o GraphQL
      // mais responsivo até certo ponto
      cache: GraphQLCache(),
    ));

    //Por fim nós colocamos o GraphQLProvider antes de chamar o Material
    // dessa forma garantimos que podemos usar e passar os elementos do graphQL
    // por/para qualquer ponto da nossa Widget Tree (Top-to-Bottom)

    return GraphQLProvider(
      client: client,
      child: MaterialApp(home: ContinentsScreen()),
    );
  }
}
