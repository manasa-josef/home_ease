import 'package:flutter/material.dart';


class TipsPage extends StatefulWidget {
  @override
  _TipsPageState createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  // Dummy data for home maintenance tips
  final List<Map<String, String>> tips = [
    {
      'title': 'Tip 1: Regularly Inspect Your Roof',
      'details': 
        'One of the most important parts of your home is the roof. Over time, weather elements like rain, wind, and snow can damage shingles, cause leaks, and lead to structural issues. Regularly inspect your roof to ensure there are no signs of damage or wear and tear. If you notice any issues, it’s crucial to address them immediately before they become more expensive to fix. It’s recommended to inspect your roof at least once a year and after major storms to maintain its condition.'
    },
    {
      'title': 'Tip 2: Clean and Maintain Gutters',
      'details': 
        'Gutters are essential for directing water away from your home, preventing water damage to your roof, siding, and foundation. However, gutters can become clogged with leaves, dirt, and debris, especially during fall. Cleaning your gutters at least twice a year — once in the spring and once in the fall — can prevent water overflow and damage. Consider installing gutter guards to reduce debris buildup and make cleaning easier.'
    },
    {
      'title': 'Tip 3: Inspect Plumbing Regularly',
      'details': 
        'Your plumbing system is essential to your home’s functionality. Leaky pipes, clogged drains, and faulty water heaters can lead to water damage and costly repairs if not addressed early. Regularly check under sinks, around toilets, and in the basement for any signs of leaks or water damage. Consider scheduling an annual plumbing inspection to ensure your pipes, faucets, and drains are in good working order.'
    },
    {
      'title': 'Tip 4: Maintain Your HVAC System',
      'details': 
        'Your HVAC system is key to keeping your home comfortable throughout the year. Dirty filters, blocked ducts, or poorly maintained components can reduce efficiency and increase your energy bills. It’s recommended to change your air filters every 3 months, have your HVAC system professionally serviced once a year, and ensure the vents are clean and unobstructed. Regular maintenance can extend the lifespan of your HVAC unit and keep your home at the perfect temperature.'
    },
    {
      'title': 'Tip 5: Check and Replace Smoke Detectors',
      'details': 
        'Smoke detectors are crucial for the safety of your home and family. Test your smoke detectors monthly, and replace the batteries at least once a year. It’s also important to replace the smoke detectors themselves every 10 years or according to the manufacturer’s recommendation. Keeping your smoke detectors in good working order can help prevent fire hazards and give you peace of mind.'
    }
  ];

  // List to track which tips' details are visible
  List<bool> _isVisible = [false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Maintenance Tips'),
      ),
      body: ListView.builder(
        itemCount: tips.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tips[index]['title']!,
                        style: TextStyle(
                          fontSize: 14, // Reduced font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isVisible[index] ? Icons.remove : Icons.add,
                          color: const Color.fromARGB(255, 65, 136, 78),
                          size: 20, // Adjusted icon size
                        ),
                        onPressed: () {
                          setState(() {
                            _isVisible[index] = !_isVisible[index];
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isVisible[index])
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        tips[index]['details']!,
                        style: TextStyle(
                          fontSize: 12, // Reduced font size for details
                          color: Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
