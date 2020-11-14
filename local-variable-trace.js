insight.on('enter', function(ctx, frame) {
   print('camel_case for ' + frame.str);
}, {
   roots: true,
   rootNameFilter: 'camel_case'
});
