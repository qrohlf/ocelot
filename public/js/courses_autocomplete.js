$(document).ready(function() {

    var engine = new Bloodhound({
      local: [{value: 'red'}, {value: 'blue'}, {value: 'green'} , {value: 'yellow'}, {value: 'violet'}, {value: 'brown'}, {value: 'purple'}, {value: 'black'}, {value: 'white'}],
      datumTokenizer: function(d) {
        return Bloodhound.tokenizers.whitespace(d.value); 
      },
      queryTokenizer: Bloodhound.tokenizers.whitespace,    
      prefetch: {
        url: window.location.origin+'/courses/json',
        // the json file contains an array of strings, but the Bloodhound
        // suggestion engine expects JavaScript objects so this converts all of
        // those strings
        filter: function(list) {
          var filtered = $.map(list, function(course) { return {value: course}; });
          console.log(filtered);
          alert('filter complete');
          return filtered;
        }
      }
    });

    engine.initialize();

    $('#courses').tokenfield({
      typeahead: {
        source: engine.ttAdapter()
      }
    });
});