function varargout = getCueData(type,subtype)
% GETCUEDATA Master file for cue types
%
%   LIST = GETCUEDATA
%   Get a list of cue types.
%
%   LIST = GETCUEDATA(TYPE)
%   Get a list of subtypes for TYPE.
%
%   [OPT,DSC,FCN] = GETCUEDATA(TYPE,SUBTYPE)
%   Get the cue data, descriptions, and info function for TYPE/SUBTYPE
%   cues.

% CUE: shape
options.shape.square = {};
descrip.shape.square = 'Count the number of squares.';
infofcn.shape.square = @Task.NumberLanguage.getShapePositionSizeColor;
options.shape.oval = {};
descrip.shape.oval = 'Count the number of circles.';
infofcn.shape.oval = @Task.NumberLanguage.getShapePositionSizeColor;
options.shape.ovalframe = {};
descrip.shape.ovalframe = 'Count the number of circles.';
infofcn.shape.ovalframe = @Task.NumberLanguage.getShapePositionSizeColor;
options.shape.rect = {};
descrip.shape.rect = 'Count the number of rectangles.';
infofcn.shape.rect = @Task.NumberLanguage.getShapePositionSizeColor;
options.shape.rectframe = {};
descrip.shape.rectframe = 'Count the number of rectangles.';
infofcn.shape.rectframe = @Task.NumberLanguage.getShapePositionSizeColor;
options.shape.triangle = {};
descrip.shape.triangle = 'Count the number of triangles.';
infofcn.shape.triangle = @Task.NumberLanguage.getShapePositionSizeColor;
options.shape.poly = {};
descrip.shape.poly = 'Count the number of polygons.';
infofcn.shape.poly = @Task.NumberLanguage.getShapePositionSizeColor;
options.shape.polyframe = {};
descrip.shape.polyframe = 'Count the number of polygons.';
infofcn.shape.polyframe = @Task.NumberLanguage.getShapePositionSizeColor;

% CUE: word
options.word.arabic = {'sifr','wahid','ithnan','thalatha','arba''a','khamsa','sitta','sab''a','thamaniya','tis''ah'};
descrip.word.arabic = 'The number is written out in the Arabic language.';
infofcn.word.arabic = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.danish = {'nul','en','to','tre','fire','fem','seks','syv','otte','ni'};
descrip.word.danish = 'The number is written out in the Danish language.';
infofcn.word.danish = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.english = {'zero','one','two','three','four','five','six','seven','eight','nine'};
descrip.word.english = 'The number is written out in English.';
infofcn.word.english = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.french = {'zero','un','deux','trois','quatre','cinq','six','sept','huit','neuf'};
descrip.word.french = 'The number is written out in French.';
infofcn.word.french = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.german = {'null','eins','zwei','drei','vier','funf','sechs','sieben','acht','neun'};
descrip.word.german = 'The number is written out in German.';
infofcn.word.german = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.japanese = {'zero','ichi','ni','san','yon','go','roku','nana','hachi','kyu'};
descrip.word.japanese = 'The number is written out in Japanese.';
infofcn.word.japanese = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.latin = {'nihil','unus','duo','tres','quattuor','sex','quinque','septem','octo','novem'};
descrip.word.latin = 'The number is written out in Latin.';
infofcn.word.latin = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.mandarin = {'ling','yi','er','san','si','wu','liu','qi','ba','jiu'};
descrip.word.mandarin = 'The number is written out in Mandarin.';
infofcn.word.mandarin = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.portuguese = {'zero','um','dois','três','quatro','cinco','seis','sete','oito','nove'};
descrip.word.portuguese = 'The number is written out in Portuguese.';
infofcn.word.portuguese = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.russian = {'????','????','???','???','??????','????','?????','????','??????','??????'};
descrip.word.russian = 'The number is written out in Russian.';
infofcn.word.russian = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.spanish = {'cero','uno','dos','tres','cuatro','cinco','seis','siete','ocho','nueve'};
descrip.word.spanish = 'The number is written out in Spanish.';
infofcn.word.spanish = @Task.NumberLanguage.getWordPositionSizeColor;
options.word.tagalog = {'wala','isa','dalawa','tatlo','apat','lima','anim','pito','walo','siyam'};
descrip.word.tagalog = 'The number is written out in Tagalog.';
infofcn.word.tagalog = @Task.NumberLanguage.getWordPositionSizeColor;

% CUE: character
options.character.roman = {'','I','II','III','IV','V','VI','VII','VIII','IX'};
descrip.character.roman = 'read the number as Roman numerals.';
infofcn.character.roman = @Task.NumberLanguage.getCharacterPositionSizeColor;
options.character.european = {'0','1','2','3','4','5','6','7','8','9'};
descrip.character.european = 'The number is presented as a normal character.';
infofcn.character.european = @Task.NumberLanguage.getCharacterPositionSizeColor;
options.character.mandarin = {12295,19968,20108,19977,22235,20116,20845,19971,20843,20061};
descrip.character.mandarin = 'The number is presented as a Chinese character.';
infofcn.character.mandarin = @Task.NumberLanguage.getCharacterPositionSizeColor;
options.character.arabic = {1632,1633,1634,1635,1636,1637,1638,1639,1640,1641};
descrip.character.arabic = 'The number is presented as character from Arabic script.';
infofcn.character.arabic = @Task.NumberLanguage.getCharacterPositionSizeColor;
options.character.korean = {50689,[54616 45208],46168,49483,45367,[45796 49455],[50668 49455],[51068 44273],[50668 45919],[50500 54857]};
descrip.character.korean = 'The number is presented as a Korean character.';
infofcn.character.korean = @Task.NumberLanguage.getCharacterPositionSizeColor;

% CUE: symbols (unicode)
options.unicode.roman = {'049',['049';'049'],['049';'049';'049'],['049';'056'],'056',['056';'049'],['056';'049';'049'],['056';'049';'049';'049'],['049';'058']};
descrip.unicode.roman = 'The number is presented as a Roman numeral.';
infofcn.unicode.roman = @Task.NumberLanguage.getCharacterPositionSizeColor;
options.unicode.european = {'030','031','032','033','034','035','036','037','038','039'};
descrip.unicode.european = 'The number is presented as a normal character.';
infofcn.unicode.european = @Task.NumberLanguage.getCharacterPositionSizeColor;
options.unicode.mandarin = {'3007','4e00','4e8c','4e09','56db','4e94','516d','4e03','516b','4e5d'};
descrip.unicode.mandarin = 'The number is presented as a Chinese character.';
infofcn.unicode.mandarin = @Task.NumberLanguage.getCharacterPositionSizeColor;
options.unicode.arabic = {'660','661','662','663','664','665','666','667','668','669'};
descrip.unicode.arabic = 'The number is presented as character from Arabic script.';
infofcn.unicode.arabic = @Task.NumberLanguage.getCharacterPositionSizeColor;

% CUE: image
options.image.fingers = [arrayfun(@(x)sprintf('fingers/set3/rh0f_lh%df.png',x),0:5,'UniformOutput',false) arrayfun(@(x)sprintf('fingers/set3/rh%df_lh5f.png',x),1:5,'UniformOutput',false)];
descrip.image.fingers = 'The number is presented as the number of fingers held up.';
infofcn.image.fingers = @Task.NumberLanguage.getImagePositionSizeColor;

% CUE: object
options.object.onion = {'TransparentBackgrounds/onion.png'};
descrip.object.onion = 'Count the number of onions on the screen.';
infofcn.object.onion = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.apple = {'TransparentBackgrounds/apple.png'};
descrip.object.apple = 'Count the number of apples on the screen.';
infofcn.object.apple = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.rock = {'TransparentBackgrounds/rock.png'};
descrip.object.rock = 'Count the number of rocks on the screen.';
infofcn.object.rock = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.paper = {'TransparentBackgrounds/paper_parchment.png'};
descrip.object.paper = 'Count the number of papers on the screen.';
infofcn.object.paper = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.scissors = {'TransparentBackgrounds/scissors_orange.png'};
descrip.object.scissors = 'Count the number of scissors on the screen.';
infofcn.object.scissors = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.penguin = {'TransparentBackgrounds/penguin.png'};
descrip.object.penguin = 'Count the number of penguins on the screen.';
infofcn.object.penguin = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.money_bag = {'TransparentBackgrounds/money_bag.png'};
descrip.object.money_bag = 'Count the number of money bags on the screen.';
infofcn.object.money_bag = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.girl_cartoon = {'TransparentBackgrounds/girl_cartoon.png'};
descrip.object.girl_cartoon = 'Count the number of cartoon girls on the screen.';
infofcn.object.girl_cartoon = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.girl_jeans = {'TransparentBackgrounds/girl_jeans.png'};
descrip.object.girl_jeans = 'Count the number of girls in jeans on the screen.';
infofcn.object.girl_jeans = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.girl_skirt = {'TransparentBackgrounds/girl_skirt.png'};
descrip.object.girl_skirt = 'Count the number of girls in skirts on the screen.';
infofcn.object.girl_skirt = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.girl_dress = {'TransparentBackgrounds/girl_dress.png'};
descrip.object.girl_dress = 'Count the number of girls in dresses on the screen.';
infofcn.object.girl_dress = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.man_rollerblades = {'TransparentBackgrounds/man_rollerblades.png'};
descrip.object.man_rollerblades = 'Count the number of men in rollerblades on the screen.';
infofcn.object.man_rollerblades = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.man_suit = {'TransparentBackgrounds/man_suit.png'};
descrip.object.man_suit = 'Count the number of men in suits on the screen.';
infofcn.object.man_suit = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.man_napoleon = {'TransparentBackgrounds/man_napoleondynamite.png'};
descrip.object.man_napoleon = 'Count the number of Napoleon Dynamites on the screen.';
infofcn.object.man_napoleon = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.paper_parchment = {'TransparentBackgrounds/paper_parchment.png'};
descrip.object.paper_parchment = 'Count the number of papers on the screen.';
infofcn.object.paper_parchment = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.skull_evil = {'TransparentBackgrounds/skull_evil.png'};
descrip.object.skull_evil = 'Count the number of skulls on the screen.';
infofcn.object.skull_evil = @Task.NumberLanguage.getObjectPositionSizeColor;
options.object.skull_half = {'TransparentBackgrounds/skull_half.png'};
descrip.object.skull_half = 'Count the number of skulls on the screen.';
infofcn.object.skull_half = @Task.NumberLanguage.getObjectPositionSizeColor;

% CUE: sound
options.sound.english = arrayfun(@(x)sprintf('numbers/english/%d.wav',x),0:9,'UniformOutput',false);
descrip.sound.english = 'Listen to the number in English.';
infofcn.sound.english = @Task.NumberLanguage.getSoundPositionSizeColor;
options.sound.french = arrayfun(@(x)sprintf('numbers/french/%d.wav',x),0:9,'UniformOutput',false);
descrip.sound.french = 'Listen to the number in French.';
infofcn.sound.french = @Task.NumberLanguage.getSoundPositionSizeColor;
options.sound.german = arrayfun(@(x)sprintf('numbers/german/%d.wav',x),0:9,'UniformOutput',false);
descrip.sound.german = 'Listen to the number in German.';
infofcn.sound.german = @Task.NumberLanguage.getSoundPositionSizeColor;
options.sound.italian = arrayfun(@(x)sprintf('numbers/italian/%d.wav',x),0:9,'UniformOutput',false);
descrip.sound.italian = 'Listen to the number in Italian.';
infofcn.sound.italian = @Task.NumberLanguage.getSoundPositionSizeColor;
options.sound.korean = arrayfun(@(x)sprintf('numbers/korean/%d.wav',x),0:9,'UniformOutput',false);
descrip.sound.korean = 'Listen to the number in Korean.';
infofcn.sound.korean = @Task.NumberLanguage.getSoundPositionSizeColor;
options.sound.mandarin = arrayfun(@(x)sprintf('numbers/mandarin/%d.wav',x),0:9,'UniformOutput',false);
descrip.sound.mandarin = 'Listen to the number in Mandarin.';
infofcn.sound.mandarin = @Task.NumberLanguage.getSoundPositionSizeColor;
options.sound.portuguese = arrayfun(@(x)sprintf('numbers/portuguese/%d.wav',x),0:9,'UniformOutput',false);
descrip.sound.portuguese = 'Listen to the number in Portuguese.';
infofcn.sound.portuguese = @Task.NumberLanguage.getSoundPositionSizeColor;
options.sound.russian = arrayfun(@(x)sprintf('numbers/russian/%d.wav',x),0:9,'UniformOutput',false);
descrip.sound.russian = 'Listen to the number in Russian.';
infofcn.sound.russian = @Task.NumberLanguage.getSoundPositionSizeColor;
options.sound.spanish = arrayfun(@(x)sprintf('numbers/spanish/%d.wav',x),0:9,'UniformOutput',false);
descrip.sound.spanish = 'Listen to the number in Spanish.';
infofcn.sound.spanish = @Task.NumberLanguage.getSoundPositionSizeColor;
options.sound.morse = arrayfun(@(x)sprintf('numbers/morse/mc%02d.wav',x),0:9,'UniformOutput',false);
descrip.sound.morse = 'Listen to the number in morse code.';
infofcn.sound.morse = @Task.NumberLanguage.getSoundPositionSizeColor;

% provide requested information
if nargin>=2
    try
    if nargout>=3
        varargout{3} = infofcn.(type).(subtype);
    end
    if nargout>=2
        varargout{2} = descrip.(type).(subtype);
    end
    if nargout>=1
        varargout{1} = options.(type).(subtype);
    end
    catch ME
        util.errorMessage(ME);
        keyboard
    end
elseif nargin>=1
    if nargout>=1
        varargout{1} = fieldnames(options.(type));
    end
else
    if nargout>=1
        varargout{1} = fieldnames(options);
    end
end