import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphql_demoapp/models/Continent.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class ContinentsScreen extends StatefulWidget {
  const ContinentsScreen({Key? key}) : super(key: key);

  @override
  _ContinentsScreenState createState() => _ContinentsScreenState();
}

class _ContinentsScreenState extends State<ContinentsScreen> {
  TextEditingController newContinent = new TextEditingController();
  TextEditingController newContinentCode = new TextEditingController();
  List? continentes;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GQL Continents page'),
        actions: [
          IconButton(
              onPressed: () => createNewContinent(), icon: Icon(Icons.add))
        ],
      ),
      //Como um StreamBuilder, nós colocamos o Query Widget para fazer o
      // gerenciamento dos dados em nossa tela
      body: Query(
        options: QueryOptions(document: gql(r"""
            query getContinents{
              continents{
                name
                code
              }
            }
      """), pollInterval: Duration(seconds: 10)),
        builder: (QueryResult queryResult,
            {Future<QueryResult> Function(FetchMoreOptions fetchMoreOptions)?
                fetchMore,
            Future<QueryResult?> Function()? refetch}) {
          if (queryResult.hasException) {
            print(queryResult.exception);
            return Center(
                child: ElevatedButton(
              child: Text('Refetch'),
              onPressed: () => refetch,
            ));
          } else if (queryResult.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          continentes = queryResult.data!['continents'];
          return ListView.builder(
            itemBuilder: (_, int index) {
              Continent continent = Continent.fromJson(continentes![index]);
              return Column(
                children: [
                  Dismissible(
                    key: Key(continent.code!),
                    confirmDismiss: (DismissDirection dismissDirection) =>
                        shootDeleteCOnfirmationDialog(continent),
                    onDismissed: (DismissDirection dismissDirection) =>
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${continent.name} foi apagado'))),
                    child: ListTile(
                      title: Text(continent.name!),
                      subtitle: Text(continent.code!),
                    ),
                  ),
                  Divider()
                ],
              );
            },
            itemCount: continentes!.length,
          );
        },
      ),
    );
  }

  createNewContinent() {
    showDialog(
        context: context,
        builder: (_) {
          // o widget responsável por nos permitir fazer modificações
          return Mutation(
            options: MutationOptions(
              document: gql("""
                                 mutation MyMutation(\$code: bpchar!, \$name: String!) {
                                  insert_continents(objects: {code: \$code, name: \$name}) {
                                   returning{
                                     code
                                       name
                                             }
                                                }
                                                  }
                                """),
              // faz a verificação do que já possui em Cache com o resultado
              // gerado após a mutation para manter os resultados na App actualizados
              update: (GraphQLDataProxy cache, QueryResult? result) {
                return cache;
              },
              onCompleted: (dynamic resultData) {
                print(resultData);
              },
            ),

            //vamos fazer o build do widget que nos irá ajudar a correr executar
            // a mutation
            builder: (
              //RunMutation é responsável por executar a estrutura (funcção) da
              // mutation já definida acima junto com os dados (parámetros)
              RunMutation runMutation,
              //pegar o resultado após a execução
              QueryResult? result,
            ) {
              return Container(
                child: AlertDialog(
                  title: Text('Add Continent'),
                  content: Container(
                    height: MediaQuery.of(context).size.height / 6,
                    width: MediaQuery.of(context).size.width,
                    child: Form(
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                                labelText: 'Código',
                                hintText: 'Código do Continente',
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(width: 2))),
                            controller: newContinentCode,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                                labelText: 'Nome',
                                hintText: 'Nome do Continente',
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(width: 2))),
                            controller: newContinent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          if (newContinentCode.text != '' ||
                              newContinent.text != '') {
                            //de modo a correr a mutation nós chamamos o
                            // runMutation e pasamos as variáveis necessárias
                            // como Mapa
                            runMutation({
                              "code": newContinentCode.text,
                              "name": newContinent.text
                            });

                            newContinentCode.clear();
                            newContinent.clear();
                          }
                        },
                        child: Text('Add Continent'))
                  ],
                ),
              );
            },
          );
        });
  }

  Future<bool> shootDeleteCOnfirmationDialog(Continent continent) async {
    return await showDialog(
        context: context,
        builder: (_) {
          return Mutation(
              options: MutationOptions(
                document: gql("""
          mutation MyMutation(\$code:bpchar! ) {
            delete_continents_by_pk(code: \$code) {
              name
            }
          }
          """),
                update: (GraphQLDataProxy cache, QueryResult? result) {
                  return cache;
                },
                onCompleted: (dynamic resultData) {
                  print(resultData);
                },
              ),
              builder: (RunMutation runMutation, QueryResult? queryResult) {
                String _dialogTitle = 'Deseja mesmo apagar ${continent.name}?';
                String _dialogContent = 'Esta acção é irreversível';

                return Platform.isIOS
                    ? CupertinoAlertDialog(
                        title: Text(_dialogTitle),
                        content: Text(_dialogContent),
                        actions: [
                          TextButton(
                              child: Text('SIM'),
                              onPressed: () {
                                runMutation({"code": continent.code});
                                setState(() {
                                  continentes!.remove(continent);
                                });
                                Navigator.pop(context, true);
                              }),
                          TextButton(
                            child: Text('NÃO'),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      )
                    : AlertDialog(
                        title: Text(_dialogTitle),
                        content: Text(_dialogContent),
                        actions: [
                          TextButton(
                              child: Text('SIM'),
                              onPressed: () {
                                runMutation({"code": continent.code});
                                setState(() {
                                  continentes!.remove(continent);
                                });
                                Navigator.pop(context, true);
                              }),
                          TextButton(
                            child: Text('NÃO'),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      );
              });
        });
  }
}
