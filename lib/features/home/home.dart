import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const .all(0.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      'Selamat Pagi!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Nama User',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: .bold,
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const CircleAvatar(child: Icon(Icons.person)),
              ],
            ),
            const SizedBox(height: 16),
            SearchAnchor.bar(
              suggestionsBuilder: (context, controller) {
                return <Widget>[Text('halo')];
              },
              barHintText: 'Cari Pelatihan',
              barElevation: WidgetStateProperty.all(0),
              barPadding: WidgetStateProperty.all(
                const .symmetric(horizontal: 16, vertical: 0),
              ),
              barShape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              viewHintText: 'Cari Pelatihan',
              viewShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rekomendasi Pelatihan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: .horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    width: MediaQuery.of(context).size.width * .9,
                    height: 250,
                    margin: const .only(right: 8),
                    padding: const .all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: .start,
                      children: [
                        Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              'Pelatihan',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Nama Pelatihan',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: .bold,
                                color: Colors.black,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const CircleAvatar(child: Icon(Icons.person)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: .vertical,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const .only(right: 16),
                    padding: const .all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Pelatihan'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
