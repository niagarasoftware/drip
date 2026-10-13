import sys

with open('lib/modules/irrigation_report/view/scrollingTable.dart', 'r', encoding='utf-8') as f:
    content = f.read()

s1 = '''  Widget _buildClickableRow(int rowIndex, Widget child) {
    return Tooltip(
      message: 'Tap row to view Sensor Analytics',
      waitDuration: const Duration(milliseconds: 600),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // if (widget.onSequenceClicked != null) {
          //   // Attempt to find sequence name if available
          //   String seqName = '';
          //   if (widget.generalColumnData.length > rowIndex) {
          //     for (int j = 0; j < widget.generalColumn.length; j++) {
          //       if (['Sequence', 'Valves', 'Valve']
          //           .contains(widget.generalColumn[j])) {
          //         if (widget.generalColumnData[rowIndex] != null &&
          //             j < widget.generalColumnData[rowIndex].length) {
          //           seqName =
          //               widget.generalColumnData[rowIndex][j]?.toString() ?? '';
          //           break;
          //         }
          //       }
          //     }
          //   }
          //   widget.onSequenceClicked!(seqName);
          // }
        },
        child: child,
      ),
    );
  }'''
r1 = '''  Widget _buildClickableRow(int rowIndex, Widget child) {
    return child;
  }'''

content = content.replace(s1, r1)

s2 = '''                                                        InkWell(
                                                          onTap: () {
                                                            if (widget
                                                                    .onSequenceClicked !=
                                                                null) {
                                                              widget.onSequenceClicked!(
                                                                  '\');
                                                            }
                                                          },
                                                          child: Container('''
r2 = '''                                                        Container('''
content = content.replace(s2, r2)

s3 = '''                                                                        ),
                                                                      ),
                                                                      
                                                                    ],
                                                                  ))),
                                                        )'''
r3 = '''                                                                        ),
                                                                      ),
                                                                      
                                                                    ],
                                                                  )),
                                                        )'''
content = content.replace(s3, r3)

s4 = '''                                                            const SizedBox(
                                                                width: 4),
                                                            InkWell(
                                                              onTap: () {
                                                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .analytics_outlined,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                            ),'''
r4 = ''''''
content = content.replace(s4, r4)

s5 = '''                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                if (widget.onSequenceClicked != null) widget.onSequenceClicked!('');
                              },
                              child: const Icon(Icons.analytics_outlined,
                                  size: 14, color: Colors.blue),
                            ),'''
r5 = ''''''
content = content.replace(s5, r5)

with open('lib/modules/irrigation_report/view/scrollingTable.dart', 'w', encoding='utf-8') as f:
    f.write(content)
