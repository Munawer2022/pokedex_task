import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PokemonListPage(),
    );
  }
}

class PokemonListPage extends StatefulWidget {
  const PokemonListPage({super.key});

  @override
  _PokemonListPageState createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> {
  int _offset = 0;
  final int _limit = 20;
  late List<Map<String, dynamic>> _pokemonList = [];
  bool _isLoading = false; // Add a flag to track loading state

  Map<String, String> _typeColors = {
    "normal": "#A8A77A",
    "fire": "#EE8130",
    "water": "#6390F0",
    "electric": "#F7D02C",
    "grass": "#7AC74C",
    "ice": "#96D9D6",
    "fighting": "#C22E28",
    "poison": "#A33EA1",
    "ground": "#E2BF65",
    "flying": "#A98FF3",
    "psychic": "#F95587",
    "bug": "#A6B91A",
    "rock": "#B6A136",
    "ghost": "#735797",
    "dragon": "#6F35FC",
    "dark": "#705746",
    "steel": "#B7B7CE",
    "fairy": "#D685AD"
  };

  @override
  void initState() {
    super.initState();
    _fetchPokemon();
  }

  Future<void> _fetchPokemon() async {
    setState(() {
      _isLoading = true; // Set loading state to true when fetching starts
    });

    try {
      final response = await http.get(Uri.parse(
          'https://pokeapi.co/api/v2/pokemon?offset=$_offset&limit=$_limit'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        final pokemonUrls =
            results.map<String>((pokemon) => pokemon['url'] as String).toList();
        final List<Map<String, dynamic>> pokemonList = [];
        for (final url in pokemonUrls) {
          final pokemonResponse = await http.get(Uri.parse(url));
          if (pokemonResponse.statusCode == 200) {
            final pokemonData =
                jsonDecode(pokemonResponse.body) as Map<String, dynamic>;
            final types = pokemonData['types'] as List<dynamic>;
            final typeNames = types
                .map<String>((type) => type['type']['name'] as String)
                .toList();
            final stats = pokemonData['stats'] as List<dynamic>;
            final statValues = stats.map<Map<String, dynamic>>((stat) {
              final statName = stat['stat']['name'] as String;
              final baseStat = stat['base_stat'] as int;
              return {
                'name': statName,
                'value': baseStat,
              };
            }).toList();
            pokemonList.add({
              'name': pokemonData['name'],
              'types': typeNames,
              'stats': statValues,
              'imageUrl': pokemonData['sprites']['front_default']
            });
          } else {
            throw Exception('Failed to load Pokémon details');
          }
        }
        setState(() {
          _pokemonList = pokemonList;
        });
      } else {
        throw Exception('Failed to load Pokémon');
      }
    } catch (e) {
      print(e);
      // Handle error here
    } finally {
      setState(() {
        _isLoading =
            false; // Set loading state to false when fetching completes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : _pokemonList.isEmpty
              ? const Center(
                  child: Text('No Pokémon found'),
                )
              : ListView.builder(
                  itemCount: _pokemonList.length,
                  itemBuilder: (context, index) {
                    final pokemon = _pokemonList[index];
                    final id = index + 1 + _offset;
                    final type = pokemon['types']
                        .first; // Assuming the first type is the main type
                    final color = _typeColors[type] ?? Colors.grey;

                    return ListTile(
                      title: Text(pokemon['name']),
                      subtitle: Text('ID: $id | Type: $type'),
                      tileColor: Color(int.parse(
                              (color as String).substring(1, 7),
                              radix: 16) +
                          0xFF000000),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PokemonDetailsPage(
                                id: id,
                                type: type,
                                stats: pokemon['stats'],
                                name: pokemon['name'],
                                imageUrl: pokemon['imageUrl']),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_offset > 0)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _offset -= _limit;
                });
                _fetchPokemon();
              },
              child: Icon(Icons.arrow_back),
            ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _offset += _limit;
              });
              _fetchPokemon();
            },
            child: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

class PokemonDetailsPage extends StatelessWidget {
  final String name;
  final imageUrl;
  final int id;
  final String type;
  final List<Map<String, dynamic>> stats;

  const PokemonDetailsPage(
      {required this.id,
      required this.type,
      required this.stats,
      required this.name,
      this.imageUrl});

  @override
  Widget build(BuildContext context) {
    print(imageUrl);
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Details for Pokémon with ID: $id'),
              SizedBox(height: 20),
              Text('Type: $type', style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Image.network(
                imageUrl ?? "",
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              ),
              SizedBox(height: 20),
              Text('Stats:', style: TextStyle(fontSize: 18)),
              Column(
                children: stats.map<Widget>((stat) {
                  return ListTile(
                    title: Text(stat['name']),
                    subtitle: Text('Default Value: ${stat['value']}'),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
