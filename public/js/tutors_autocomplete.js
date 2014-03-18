$(document).ready(function() {

    var engine = new Bloodhound({
      datumTokenizer: function(d) {
        return Bloodhound.tokenizers.whitespace(d.label); 
      },
      queryTokenizer: Bloodhound.tokenizers.whitespace,    
      prefetch: {
        url: window.location.origin+'/tutors/json',
        // the json file contains an array of strings, but the Bloodhound
        // suggestion engine expects JavaScript objects so this converts all of
        // those strings
        filter: function(list) {
          console.log('filter called');
          var filtered = $.map(list, function(tutor) { return {label: tutor.name, value: tutor.id}; });
          // alert('filter complete');
          return filtered;
        }
      }
    });

    engine.initialize();

    $('#tutors').tokenfield({
      typeahead: {
        source: engine.ttAdapter(),
        displayKey: 'label'
      }
    });

    $('.tt-input').on('typeahead:selected', function (e, datum) {
        console.log('typeahead:selected');
        console.log(datum);
    });
    $('#tutors').on('tokenfield:createtoken', function (e) {
        // Über-simplistic e-mail validation
        // console.log(e.token);
        // console.log($(this).tokenfield('getTokensList'));
        // e.token.value = 'foo';
      });
    $('#tutors').on('tokenfield:preparetoken', function (e) {
        // console.log(e);
        // e.token.value = 'foo';
      })
});