const CIVS = [
    'Aztecs', 'Berbers', 'Britons', 'Bulgarians', 'Burgundians', 'Burmese',
    'Byzantines', 'Celts', 'Chinese', 'Cumans', 'Ethiopians', 'Franks',
    'Goths', 'Huns', 'Incas', 'Indians', 'Italians', 'Japanese', 'Khmer',
    'Koreans', 'Lithuanians', 'Magyars', 'Malay', 'Malians', 'Mayans',
    'Mongols', 'Persians', 'Portuguese', 'Saracens', 'Sicilians', 'Slavs',
    'Spanish', 'Tatars', 'Teutons', 'Turks', 'Vietnamese', 'Vikings'
]


update_element = function(event, ui){
    var label = ui.item.label;
    var targetid = event.target.id;
    $("."+targetid).hide();
    $("#" +targetid + "-" + label).show();
}

init_autocomplete = function (id) {
    $("#" + id).autocomplete({
        source: CIVS,
        autoFocus: false,
        minLength: 0,
        select: update_element
    });
      
    $("#" + id ).click(function() {
        $( "#" + id ).autocomplete( "search", "" );
    });
}



$(document).ready(function(){
    init_autocomplete("cvcip");
})

