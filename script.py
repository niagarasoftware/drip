with open('lib/modules/irrigation_report/view/scrollingTable.dart', 'r') as f:
    lines = f.readlines()

count = 0
for i, line in enumerate(lines):
    if 'style: TextStyle(fontSize: 12,fontWeight: FontWeight.normal),overflow: TextOverflow.ellipsis,),' in line:
        if 'child: Text' in line:
            start = line.find('Text(') + 6
            end = line.find("','style")
            if end == -1: end = line.find("',style")
            
            var_part = line[start:end]
            
            replacement = f'''child: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Flexible(
      child: Text('{var_part}', style: const TextStyle(fontSize: 12,fontWeight: FontWeight.normal), overflow: TextOverflow.ellipsis,),
    ),
    const SizedBox(width: 4),
    const Icon(Icons.analytics_outlined, size: 14, color: Colors.blue),
  ],
),'''
            leading_spaces = len(line) - len(line.lstrip())
            indented = '\n'.join([(' ' * leading_spaces) + l if idx > 0 else l for idx, l in enumerate(replacement.split('\n'))])
            
            lines[i] = (' ' * leading_spaces) + indented + '\n'
            count += 1

print(f'Replaced {count} occurrences')

with open('lib/modules/irrigation_report/view/scrollingTable.dart', 'w') as f:
    f.writelines(lines)
