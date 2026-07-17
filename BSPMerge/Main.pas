unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes, System.Math, System.RegularExpressions, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.StdCtrls, Vcl.CheckLst, Vcl.ExtCtrls, Vcl.Samples.Spin,
  AsmUtils64, RSoftClasses64, RSoftUtils64, CelestialMechanics, JPLEphemeris, BSPFile, BSPXFile, Chebyshev, MDA, Vec4D;

type
  TMainForm = class(TForm)
    OpenDialog: TOpenDialog;
    Splitter: TSplitter;
    Panel1: TPanel;
    Memo: TMemo;
    Panel0: TPanel;
    CheckListBox: TCheckListBox;
    SaveDialog: TSaveDialog;
    PopupMenu: TPopupMenu;
    PMAll: TMenuItem;
    PMNone: TMenuItem;
    Panel2: TPanel;
    OpenBtn: TButton;
    Panel3: TPanel;
    StartBtn: TButton;
    CBtpc: TCheckBox;
    NumSat: TSpinEdit;
    Label1: TLabel;
    Label3: TLabel;
    NumAst: TSpinEdit;
    Label4: TLabel;
    Label5: TLabel;
    NumKBO: TSpinEdit;
    Label6: TLabel;
    Label7: TLabel;
    FilterBtn: TButton;
    DownloadBtn: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure OpenBtnClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure SaveDialogTypeChange(Sender: TObject);
    procedure PMSelectClick(Sender: TObject);
    procedure CheckListBoxClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Panel2Resize(Sender: TObject);
    procedure FilterBtnClick(Sender: TObject);
    procedure DownloadBtnClick(Sender: TObject);
  private
    FFiles, FTargets: TStringList;
    FList, FTmin, FTmax: TCustomList;
    FDlThread: TThread;
    FExeStr: string;
    procedure CheckCoverage;
    procedure LoadBSPFiles(const Paths: array of string);
    procedure AbortDownloadClick(Sender: TObject);
  public
    HorizonsMode: Boolean;
  end;

var
  MainForm: TMainForm;
const
  TAG_HORIZONSMODE = 'HorizonsMode';
  TEMP_DIR = 'C:\temp\bspmerge';
  KBO_NUMBER_MIN = 10000;   // minor-planet number split: < this = main-belt asteroid, >= this = KBO/TNO (main-belt tops at (1467) Mashona, lowest KBO is (19521) Chaos). Used by FilterBtnClick and StartBtnClick.
  FileExt: array[1..2] of string=('.bspx', '.bsp');
  Default_Files: array[0..7] of string = (
   'https://ssd.jpl.nasa.gov/ftp/eph/planets/bsp/de440t.bsp',
   'https://ssd.jpl.nasa.gov/ftp/eph/satellites/bsp/mar099.bsp',
   'https://ssd.jpl.nasa.gov/ftp/eph/satellites/bsp/jup365.bsp',
   'https://ssd.jpl.nasa.gov/ftp/eph/satellites/bsp/sat441l.bsp',
   'https://ssd.jpl.nasa.gov/ftp/eph/satellites/bsp/ura182.bsp',
   'https://ssd.jpl.nasa.gov/ftp/eph/satellites/bsp/nep097.bsp',
   'https://ssd.jpl.nasa.gov/ftp/eph/satellites/bsp/plu060.bsp',
   'https://ssd.jpl.nasa.gov/ftp/eph/small_bodies/asteroids_de430/ast343de430.bsp'
  );
  // KBO/TNO small-body SPKs are not static files -- the Horizons API generates each one on demand
  // (EPHEM_TYPE=SPK, COMMAND='DES=<spkid>;') over the span below and returns a Type 21 kernel as base64 in JSON.
  HORIZONS_API = 'https://ssd.jpl.nasa.gov/api/horizons.api';
  EP_START = '1950-01-01';   // matches the sample KBO files' coverage (ET -1577880000 .. 4733553600)
  EP_STOP  = '2150-01-01';
  Default_Ast: array[0..342] of Int64 = (   // descending GM (CelestialMechanics.BodyConstants coefficient) -- the 343 asteroids of ast343de430.bsp
    20000001,   // (1) Ceres              1.396e-13
    20000004,   // (4) Vesta              3.855e-14
    20000002,   // (2) Pallas             3.047e-14
    20000010,   // (10) Hygieia           1.254e-14
    20000511,   // (511) Davida           8.684e-15
    20000704,   // (704) Interamnia       6.311e-15
    20000052,   // (52) Europa            5.982e-15
    20000087,   // (87) Sylvia            4.835e-15
    20000015,   // (15) Eunomia           4.511e-15
    20000003,   // (3) Juno               4.282e-15
    20000016,   // (16) Psyche            3.545e-15
    20000107,   // (107) Camilla          3.219e-15
    20000088,   // (88) Thisbe            2.653e-15
    20000007,   // (7) Iris               2.542e-15
    20000031,   // (31) Euphrosyne        2.407e-15
    20000065,   // (65) Cybele            2.092e-15
    20000209,   // (209) Dido             1.951e-15
    20000094,   // (94) Aurora            1.948e-15
    20000048,   // (48) Doris             1.909e-15
    20000154,   // (154) Bertha           1.906e-15
    20000029,   // (29) Amphitrite        1.779e-15
    20000375,   // (375) Ursula           1.772e-15
    20000532,   // (532) Herculina        1.765e-15
    20000566,   // (566) Stereoskopia     1.701e-15
    20000386,   // (386) Siegena          1.674e-15
    20000702,   // (702) Alauda           1.673e-15
    20000039,   // (39) Laetitia          1.624e-15
    20000009,   // (9) Metis              1.449e-15
    20000006,   // (6) Hebe               1.442e-15
    20000324,   // (324) Bamberga         1.381e-15
    20000130,   // (130) Elektra          1.327e-15
    20000024,   // (24) Themis            1.311e-15
    20000451,   // (451) Patientia        1.297e-15
    20000019,   // (19) Fortuna           1.240e-15
    20000372,   // (372) Palma            1.234e-15
    20000041,   // (41) Daphne            1.206e-15
    20000014,   // (14) Irene             1.186e-15
    20000423,   // (423) Diotima          1.151e-15
    20000013,   // (13) Egeria            1.139e-15
    20000069,   // (69) Hesperia          1.122e-15
    20000011,   // (11) Parthenope        1.026e-15
    20000471,   // (471) Papagena         1.015e-15
    20000120,   // (120) Lachesis         1.005e-15
    20000047,   // (47) Aglaja            9.548e-16
    20000096,   // (96) Aegle             9.429e-16
    20000476,   // (476) Hedwig           9.329e-16
    20000409,   // (409) Aspasia          9.307e-16
    20000139,   // (139) Juewa            9.260e-16
    20000747,   // (747) Winchester       8.916e-16
    20000022,   // (22) Kalliope          8.805e-16
    20000117,   // (117) Lomia            8.796e-16
    20000596,   // (596) Scheila          8.750e-16
    20000128,   // (128) Nemesis          8.585e-16
    20000085,   // (85) Io                8.411e-16
    20000046,   // (46) Hestia            8.292e-16
    20000168,   // (168) Sibylla          8.286e-16
    20000241,   // (241) Germania         8.258e-16
    20000045,   // (45) Eugenia           8.038e-16
    20000049,   // (49) Pales             8.031e-16
    20000488,   // (488) Kreusa           7.952e-16
    20000349,   // (349) Dembowska        7.777e-16
    20000146,   // (146) Lucina           7.415e-16
    20000247,   // (247) Eukrate          7.217e-16
    20000076,   // (76) Freia             7.197e-16
    20000196,   // (196) Philomela        7.188e-16
    20000187,   // (187) Lamberta         6.999e-16
    20000354,   // (354) Eleonora         6.980e-16
    20000776,   // (776) Berbericia       6.914e-16
    20000059,   // (59) Elpis             6.124e-16
    20000093,   // (93) Minerva           5.891e-16
    20000008,   // (8) Flora              5.740e-16
    20000020,   // (20) Massalia          5.713e-16
    20000089,   // (89) Julia             5.700e-16
    20000780,   // (780) Armenia          5.684e-16
    20000051,   // (51) Nemausa           5.597e-16
    20000227,   // (227) Philosophia      5.295e-16
    20000203,   // (203) Pompeja          5.180e-16
    20000181,   // (181) Eucharis         5.123e-16
    20000790,   // (790) Pretoria         5.043e-16
    20000036,   // (36) Atalante          5.014e-16
    20000328,   // (328) Gudrun           4.998e-16
    20000018,   // (18) Melpomene         4.818e-16
    20000250,   // (250) Bettina          4.694e-16
    20000095,   // (95) Arethusa          4.603e-16
    20000259,   // (259) Aletheia         4.525e-16
    20000381,   // (381) Myrrha           4.493e-16
    20000212,   // (212) Medea            4.461e-16
    20000104,   // (104) Klymene          4.414e-16
    20000056,   // (56) Melete            4.333e-16
    20000444,   // (444) Gyptis           4.247e-16
    20000216,   // (216) Kleopatra        4.143e-16
    20000762,   // (762) Pulcova          4.115e-16
    20000144,   // (144) Vibilia          4.074e-16
    20000705,   // (705) Erminia          3.912e-16
    20000268,   // (268) Adorea           3.862e-16
    20000283,   // (283) Emma             3.835e-16
    20000040,   // (40) Harmonia          3.739e-16
    20000469,   // (469) Argentina        3.648e-16
    20000173,   // (173) Ino              3.494e-16
    20000387,   // (387) Aquitania        3.438e-16
    20000028,   // (28) Bellona           3.404e-16
    20000393,   // (393) Lampetia         3.357e-16
    20000140,   // (140) Siwa             3.345e-16
    20000012,   // (12) Victoria          3.284e-16
    20000426,   // (426) Hippo            3.251e-16
    20000005,   // (5) Astraea            3.216e-16
    20000098,   // (98) Ianthe            3.186e-16
    20000410,   // (410) Chloris          3.153e-16
    20000034,   // (34) Circe             3.139e-16
    20000145,   // (145) Adeona           3.132e-16
    20000171,   // (171) Ophelia          3.026e-16
    20000121,   // (121) Hermione         3.003e-16
    20000489,   // (489) Comacina         2.878e-16
    20000357,   // (357) Ninina           2.872e-16
    20000063,   // (63) Ausonia           2.860e-16
    20000405,   // (405) Thia             2.834e-16
    20000156,   // (156) Xanthippe        2.791e-16
    20000350,   // (350) Ornamenta        2.786e-16
    20000023,   // (23) Thalia            2.767e-16
    20000148,   // (148) Gallia           2.764e-16
    20000536,   // (536) Merapi           2.733e-16
    20000150,   // (150) Nuwa             2.691e-16
    20000388,   // (388) Charybdis        2.687e-16
    20000164,   // (164) Eva              2.686e-16
    20000230,   // (230) Athamantis       2.655e-16
    20000165,   // (165) Loreley          2.645e-16
    20000090,   // (90) Antiope           2.643e-16
    20000137,   // (137) Meliboea         2.629e-16
    20000508,   // (508) Princetonia      2.600e-16
    20000690,   // (690) Wratislavia      2.586e-16
    20000027,   // (27) Euterpe           2.561e-16
    20000054,   // (54) Alexandra         2.561e-16
    20000804,   // (804) Hispania         2.553e-16
    20000618,   // (618) Elfriede         2.519e-16
    20000356,   // (356) Liguria          2.519e-16
    20000143,   // (143) Adria            2.498e-16
    20000114,   // (114) Kassandra        2.488e-16
    20000147,   // (147) Protogeneia      2.486e-16
    20000127,   // (127) Johanna          2.475e-16
    20000194,   // (194) Prokne           2.456e-16
    20000037,   // (37) Fides             2.428e-16
    20000334,   // (334) Chicago          2.414e-16
    20000419,   // (419) Aurelia          2.377e-16
    20000420,   // (420) Bertholda        2.367e-16
    20000602,   // (602) Marianna         2.281e-16
    20000595,   // (595) Polyxena         2.247e-16
    20000363,   // (363) Padua            2.239e-16
    20000238,   // (238) Hypatia          2.219e-16
    20000141,   // (141) Lumen            2.189e-16
    20000308,   // (308) Polyxo           2.165e-16
    20000791,   // (791) Ani              2.108e-16
    20000335,   // (335) Roberta          2.084e-16
    20000360,   // (360) Carlova          2.049e-16
    20000078,   // (78) Diana             2.037e-16
    20000092,   // (92) Undina            2.022e-16
    20000233,   // (233) Asterope         1.998e-16
    20000276,   // (276) Adelheid         1.992e-16
    20000021,   // (21) Lutetia           1.976e-16
    20000663,   // (663) Gerlinde         1.973e-16
    20000786,   // (786) Bredichina       1.953e-16
    20000545,   // (545) Messalina        1.952e-16
    20000159,   // (159) Aemilia          1.924e-16
    20000506,   // (506) Marion           1.907e-16
    20000074,   // (74) Galatea           1.901e-16
    20000895,   // (895) Helio            1.894e-16
    20000514,   // (514) Armida           1.886e-16
    20000042,   // (42) Isis              1.874e-16
    20000083,   // (83) Beatrix           1.846e-16
    20000654,   // (654) Zelinda          1.827e-16
    20000058,   // (58) Concordia         1.801e-16
    20000026,   // (26) Proserpina        1.781e-16
    20000788,   // (788) Hohensteina      1.771e-16
    20000517,   // (517) Edith            1.766e-16
    20000206,   // (206) Hersilia         1.749e-16
    20000772,   // (772) Tanete           1.737e-16
    20000667,   // (667) Denise           1.717e-16
    20000201,   // (201) Penelope         1.666e-16
    20000266,   // (266) Aline            1.659e-16
    20000416,   // (416) Vaticana         1.651e-16
    20000498,   // (498) Tokio            1.617e-16
    20000404,   // (404) Arsinoe          1.614e-16
    20000554,   // (554) Peraga           1.594e-16
    20000345,   // (345) Tercidina        1.589e-16
    20000176,   // (176) Iduna            1.573e-16
    20000521,   // (521) Brixia           1.558e-16
    20000751,   // (751) Faina            1.538e-16
    20000062,   // (62) Erato             1.521e-16
    20000072,   // (72) Feronia           1.509e-16
    20000200,   // (200) Dynamene         1.506e-16
    20001015,   // (1015) Christa         1.477e-16
    20000185,   // (185) Eunike           1.454e-16
    20000221,   // (221) Eos              1.454e-16
    20000135,   // (135) Hertha           1.452e-16
    20000086,   // (86) Semele            1.437e-16
    20000490,   // (490) Veritas          1.427e-16
    20000481,   // (481) Emita            1.423e-16
    20000091,   // (91) Aegina            1.420e-16
    20000124,   // (124) Alkeste          1.408e-16
    20000105,   // (105) Artemis          1.405e-16
    20000431,   // (431) Nephele          1.398e-16
    20001093,   // (1093) Freda           1.377e-16
    20000129,   // (129) Antigone         1.369e-16
    20000163,   // (163) Erigone          1.350e-16
    20000017,   // (17) Thetis            1.340e-16
    20000344,   // (344) Desiderata       1.317e-16
    20000071,   // (71) Niobe             1.312e-16
    20001171,   // (1171) Rusthawelia     1.308e-16
    20001107,   // (1107) Lictoria        1.292e-16
    20000373,   // (373) Melusina         1.291e-16
    20000103,   // (103) Hera             1.287e-16
    20000111,   // (111) Ate              1.269e-16
    20000043,   // (43) Ariadne           1.268e-16
    20000081,   // (81) Terpsichore       1.266e-16
    20000712,   // (712) Boliviana        1.260e-16
    20000412,   // (412) Elisabetha       1.257e-16
    20000275,   // (275) Sapientia        1.256e-16
    20000769,   // (769) Tatjana          1.254e-16
    20000303,   // (303) Josephina        1.225e-16
    20000070,   // (70) Panopaea          1.221e-16
    20000407,   // (407) Arachne          1.216e-16
    20000134,   // (134) Sophrosyne       1.204e-16
    20000683,   // (683) Lanzia           1.200e-16
    20000709,   // (709) Fringilla        1.193e-16
    20000739,   // (739) Mandeville       1.190e-16
    20000068,   // (68) Leto              1.171e-16
    20000740,   // (740) Cantabia         1.151e-16
    20000773,   // (773) Irmintraud       1.150e-16
    20000455,   // (455) Bruchsalia       1.148e-16
    20000505,   // (505) Cava             1.143e-16
    20000449,   // (449) Hamburga         1.138e-16
    20000362,   // (362) Havnia           1.128e-16
    20000110,   // (110) Lydia            1.127e-16
    20000713,   // (713) Luscinia         1.115e-16
    20000424,   // (424) Gratia           1.102e-16
    20000346,   // (346) Hermentaria      1.099e-16
    20000635,   // (635) Vundtia          1.092e-16
    20000675,   // (675) Ludmilla         1.049e-16
    20000097,   // (97) Klotho            1.027e-16
    20000599,   // (599) Luisa            1.012e-16
    20000385,   // (385) Ilmatar          9.976e-17
    20000674,   // (674) Rachele          9.935e-17
    20000162,   // (162) Laurentia        9.901e-17
    20000358,   // (358) Apollonia        9.671e-17
    20001467,   // (1467) Mashona         9.539e-17
    20000849,   // (849) Ara              9.512e-17
    20000377,   // (377) Campania         9.303e-17
    20000191,   // (191) Kolga            9.270e-17
    20000240,   // (240) Vanadis          9.255e-17
    20000598,   // (598) Octavia          9.203e-17
    20000050,   // (50) Virginia          9.066e-17
    20000491,   // (491) Carina           9.033e-17
    20000195,   // (195) Eurykleia        8.832e-17
    20000109,   // (109) Felicitas        8.734e-17
    20000100,   // (100) Hekate           8.551e-17
    20000445,   // (445) Edna             8.532e-17
    20000365,   // (365) Corduba          8.440e-17
    20000369,   // (369) Aeria            8.337e-17
    20000035,   // (35) Leukothea         8.271e-17
    20000503,   // (503) Evelyn           8.208e-17
    20000038,   // (38) Leda              8.166e-17
    20000680,   // (680) Genoveva         8.150e-17
    20000192,   // (192) Nausikaa         8.142e-17
    20000044,   // (44) Nysa              8.120e-17
    20000322,   // (322) Phaeo            8.073e-17
    20000415,   // (415) Palatia          8.057e-17
    20001021,   // (1021) Flammario       8.020e-17
    20000304,   // (304) Olga             8.006e-17
    20000389,   // (389) Industria        8.006e-17
    20000366,   // (366) Vincentina       7.979e-17
    20000568,   // (568) Cheruskia        7.975e-17
    20000032,   // (32) Pomona            7.875e-17
    20000053,   // (53) Kalypso           7.710e-17
    20000210,   // (210) Isabella         7.663e-17
    20000735,   // (735) Marghanna        7.566e-17
    20000211,   // (211) Isolda           7.560e-17
    20000466,   // (466) Tisiphone        7.528e-17
    20000084,   // (84) Klio              7.496e-17
    20000057,   // (57) Mnemosyne         7.473e-17
    20000175,   // (175) Andromache       7.312e-17
    20000337,   // (337) Devosa           7.310e-17
    20000213,   // (213) Lilaea           7.281e-17
    20000102,   // (102) Miriam           7.271e-17
    20000313,   // (313) Chaldaea         7.188e-17
    20000626,   // (626) Notburga         7.022e-17
    20000115,   // (115) Thyra            6.974e-17
    20000326,   // (326) Tamara           6.833e-17
    20000760,   // (760) Massinga         6.805e-17
    20000696,   // (696) Leonora          6.774e-17
    20000454,   // (454) Mathesis         6.680e-17
    20000160,   // (160) Una              6.514e-17
    20000980,   // (980) Anacostia        6.347e-17
    20000236,   // (236) Honoria          6.252e-17
    20000225,   // (225) Henrietta        6.149e-17
    20000535,   // (535) Montague         6.051e-17
    20000106,   // (106) Dione            5.934e-17
    20000464,   // (464) Megaira          5.823e-17
    20000075,   // (75) Eurydike          5.803e-17
    20000814,   // (814) Tauris           5.745e-17
    20000030,   // (30) Urania            5.706e-17
    20000516,   // (516) Amherstia        5.663e-17
    20000080,   // (80) Sappho            5.647e-17
    20000569,   // (569) Misa             5.569e-17
    20000223,   // (223) Rosa             5.521e-17
    20000752,   // (752) Sulamitis        5.503e-17
    20000784,   // (784) Pickeringia      5.319e-17
    20000077,   // (77) Frigga            5.272e-17
    20000205,   // (205) Martha           5.236e-17
    20000465,   // (465) Alekto           5.187e-17
    20000691,   // (691) Lehigh           5.121e-17
    20000287,   // (287) Nephthys         5.107e-17
    20000694,   // (694) Ekard            5.101e-17
    20000329,   // (329) Svea             5.023e-17
    20000099,   // (99) Dike              5.015e-17
    20000079,   // (79) Eurynome          4.824e-17
    20000172,   // (172) Baucis           4.659e-17
    20000604,   // (604) Tekmessa         4.646e-17
    20000224,   // (224) Oceana           4.638e-17
    20000485,   // (485) Genua            4.588e-17
    20000914,   // (914) Palisana         4.449e-17
    20000593,   // (593) Titania          4.315e-17
    20000909,   // (909) Ulla             3.965e-17
    20000584,   // (584) Semiramis        3.885e-17
    20000082,   // (82) Alkmene           3.829e-17
    20000442,   // (442) Eichsfeldia      3.768e-17
    20000198,   // (198) Ampella          3.469e-17
    20000547,   // (547) Praxedis         3.289e-17
    20000025,   // (25) Phocaea           3.256e-17
    20000177,   // (177) Irma             3.195e-17
    20000113,   // (113) Amalthea         3.082e-17
    20000112,   // (112) Iphigenia        3.052e-17
    20000338,   // (338) Budrosa          2.865e-17
    20000347,   // (347) Pariana          2.484e-17
    20001036,   // (1036) Ganymed         2.113e-17
    20000778,   // (778) Theobalda        2.059e-17
    20000132,   // (132) Aethra           1.750e-17
    20000591,   // (591) Irmgard          1.565e-17
    20000060,   // (60) Echo              1.483e-17
    20000336,   // (336) Lacadiera        1.425e-17
    20000432,   // (432) Pythia           1.360e-17
    20000118,   // (118) Peitho           1.316e-17
    20000623,   // (623) Chimaera         1.012e-17
    20000585,   // (585) Bilkis           9.503e-18
    20000433    // (433) Eros             9.951e-19
  );
  Default_TNO: array[0..11] of Int64 = (   // descending GM (km^3/s^2, actual value; dwarf planets use coeff*AU^3*SEC2DAY^2, small binaries use mass_kg*G_CONST)
    20136199,   // Eris        1.115e+03
    20136108,   // Haumea      2.674e+02
    20136472,   // Makemake    1.539e+02
    20225088,   // Gonggong    1.160e+02
    20050000,   // Quaoar      6.860e+01
    20090482,   // Orcus       4.220e+01
    20120347,   // Salacia     2.920e+01
    50031846,   // 1998 WW31   1.774e-01
    20469705,   // Kagara      1.455e-01
    50092534,   // 2001 QW322  1.435e-01
    20612687,   // 2003 UN284  9.411e-02
    20612095    // 1999 OJ4    2.700e-02
  );
  // Approximate download sizes (bytes), index-matched to Default_Files, for the pre-download confirmation.
  // The JPL FTP kernels are large (~8 GB total); each Horizons KBO SPK is ~3.5 MB.
  Default_FileSizes: array[0..7] of Int64 = (
    152747008,    // de440t.bsp       ~146 MB
    1180484608,   // mar099.bsp       ~1.1 GB
    1108796416,   // jup365.bsp       ~1.0 GB
    638564352,    // sat441l.bsp      ~609 MB
    698004480,    // ura182.bsp       ~666 MB
    3232677888,   // nep097.bsp       ~3.0 GB
    116884480,    // plu060.bsp       ~111 MB
    1205926912    // ast343de430.bsp  ~1.1 GB
  );

implementation

{$R *.dfm}

uses
  Progress, System.Net.HttpClient, System.Net.URLClient, System.JSON, System.NetEncoding, System.IOUtils;

function IdxOfTarget(const D: array of TBSPXDesc; TargetID: Int64): Int64;
begin
  for Result := 0 to High(D) do
    if D[Result].TargetID = TargetID then Exit;
  Result := -1;
end;

function ParseDEHeaderConsts(const Path: string;
  out AU, CLIGHT, BETA, GAMMA, ASUN, J2SUN, J3SUN, J4SUN, RE, J2E, J3E, J4E: Double): Boolean;
// Parse a JPL DE header (header.4xx) for the unit-clean constants: GROUP 1040 = names, GROUP 1041 = values
// (positional, D-exponent notation). The header's GM's are AU^3/day^2, so GMS/GMn are deliberately NOT read
// here -- GM comes from the km^3/s^2 tpc. Any key not found stays NaN. Returns False if the file won't parse.
var
  sl, nm, vl: TStringList;
  mc: TMatchCollection;
  m: TMatch;
  k: Integer;
  txt: string;
  fmt: TFormatSettings;
  function ValOf(const key: string): Double;
  var i: Integer; s: string;
  begin
    Result := NaN;
    i := nm.IndexOf(key);
    if (i >= 0) and (i < vl.Count) then
     begin
      s := StringReplace(vl[i], 'D', 'E', [rfReplaceAll, rfIgnoreCase]);
      if not TryStrToFloat(s, Result, fmt) then Result := NaN;
     end;
  end;
begin
  AU:=NaN; CLIGHT:=NaN; BETA:=NaN; GAMMA:=NaN; ASUN:=NaN; J2SUN:=NaN; J3SUN:=NaN; J4SUN:=NaN;
  RE:=NaN; J2E:=NaN; J3E:=NaN; J4E:=NaN;
  Result := False;
  if not FileExists(Path) then Exit;
  fmt := TFormatSettings.Invariant;
  sl := TStringList.Create; nm := TStringList.Create; vl := TStringList.Create;
  try
   sl.LoadFromFile(Path);
   txt := sl.Text;
   m := TRegEx.Match(txt, 'GROUP\s+1040\s+\d+\s+(.*?)GROUP\s+1041', [roSingleLine]);
   if not m.Success then Exit;
   mc := TRegEx.Matches(m.Groups[1].Value, '[A-Za-z][A-Za-z0-9_]*');
   for k := 0 to mc.Count-1 do nm.Add(mc[k].Value);
   m := TRegEx.Match(txt, 'GROUP\s+1041\s+\d+\s+(.*?)(GROUP\s+1050|$)', [roSingleLine]);
   if not m.Success then Exit;
   mc := TRegEx.Matches(m.Groups[1].Value, '[-+]?\d\.\d+[DdEe][-+]?\d+');
   for k := 0 to mc.Count-1 do vl.Add(mc[k].Value);
   AU:=ValOf('AU'); CLIGHT:=ValOf('CLIGHT'); BETA:=ValOf('BETA'); GAMMA:=ValOf('GAMMA');
   ASUN:=ValOf('ASUN'); J2SUN:=ValOf('J2SUN'); J3SUN:=ValOf('J3SUN'); J4SUN:=ValOf('J4SUN');
   RE:=ValOf('RE'); J2E:=ValOf('J2E'); J3E:=ValOf('J3E'); J4E:=ValOf('J4E');
   Result := not IsNaN(AU);   // parsed OK if at least AU resolved
  finally
   vl.Free; nm.Free; sl.Free;
  end;
end;

function ParseSatelliteFigure(const BSPPath: string; PlanetNum: Int64;
  out Req, J2, J3, J4, PoleRA, PoleDec: Double): Boolean;
// Read a SATEPHGEN satellite BSP's DAF comment area (records 2..FWARD-1) and pull the planet figure:
// RADIUS, J{n}02/03/04, ZACPL{n}/ZDEPL{n} (pole RA/Dec, deg). Non-printable DAF record-boundary bytes are
// stripped so corrupted spans collapse. Returns False (file skipped) if it carries no J{n}02.
var
  fs: TFileStream;
  rec1: array[0..1023] of Byte;
  cbuf: TBytes;
  sb: TStringBuilder;
  txt: string;
  fward, cbytes, k: Integer;
  fmt: TFormatSettings;
  function ValOf(const key: string): Double;
  var mm: TMatch;
  begin
    Result := NaN;
    mm := TRegEx.Match(txt, TRegEx.Escape(key) + '\s+([-+]?\d\.\d+[Ee][-+]?\d+)');
    if mm.Success then if not TryStrToFloat(mm.Groups[1].Value, Result, fmt) then Result := NaN;
  end;
begin
  Req:=0; J2:=0; J3:=0; J4:=0; PoleRA:=0; PoleDec:=0;
  Result := False;
  if not FileExists(BSPPath) then Exit;
  fs := TFileStream.Create(BSPPath, fmOpenRead or fmShareDenyWrite);
  try
   if fs.Read(rec1, 1024) <> 1024 then Exit;
   fward := PInteger(@rec1[76])^;               // DAF file record: FWARD at byte 76
   if fward <= 2 then Exit;                      // no comment area
   cbytes := (fward-2)*1024;
   SetLength(cbuf, cbytes);
   fs.Position := 1024;
   if fs.Read(cbuf[0], cbytes) <> cbytes then Exit;
  finally
   fs.Free;
  end;
  fmt := TFormatSettings.Invariant;
  sb := TStringBuilder.Create(cbytes);
  try
   for k := 0 to cbytes-1 do
     if (cbuf[k] >= 32) and (cbuf[k] <= 126) then sb.Append(Chr(cbuf[k]));
   txt := sb.ToString;
  finally
   sb.Free;
  end;
  J2 := ValOf('J'+IntToStr(PlanetNum)+'02');
  if IsNaN(J2) then Exit;                        // no J{n}02 -> not planet PlanetNum's satellite ephemeris
  J3 := ValOf('J'+IntToStr(PlanetNum)+'03'); if IsNaN(J3) then J3:=0;   // giants may be even-zonal only
  J4 := ValOf('J'+IntToStr(PlanetNum)+'04'); if IsNaN(J4) then J4:=0;
  Req     := ValOf('RADIUS');                    if IsNaN(Req)     then Req:=0;
  PoleRA  := ValOf('ZACPL'+IntToStr(PlanetNum)); if IsNaN(PoleRA)  then PoleRA:=0;
  PoleDec := ValOf('ZDEPL'+IntToStr(PlanetNum)); if IsNaN(PoleDec) then PoleDec:=0;
  Result := True;
end;

function PCKNums(const txt, key: string; const fmt: TFormatSettings): TArray<Double>;
// The numbers inside a SPICE text-PCK assignment  "<key> = ( n0 n1 ... )"  (tolerates "+=" and D-exponents,
// and arrays spanning several lines). Uses the LAST assignment (SPICE lets a later one override an earlier).
// Empty if the key is absent. NOTE: caller must feed data-section-only text (see PCKDataOnly).
var mc: TMatchCollection; k: Integer; s: string;
begin
  SetLength(Result, 0);
  mc := TRegEx.Matches(txt, TRegEx.Escape(key) + '\s*\+?=\s*\(([^)]*)\)');
  if mc.Count = 0 then Exit;
  mc := TRegEx.Matches(mc[mc.Count-1].Groups[1].Value, '[-+]?(?:\d+\.?\d*|\.\d+)(?:[DdEe][-+]?\d+)?');
  SetLength(Result, mc.Count);
  for k := 0 to mc.Count-1 do
   begin
    s := StringReplace(mc[k].Value, 'D', 'E', [rfReplaceAll, rfIgnoreCase]);
    if not TryStrToFloat(s, Result[k], fmt) then Result[k] := 0.0;
   end;
end;

function PCKDataOnly(const Path: string): string;
// Return only the SPICE text-kernel DATA sections: lines between a "\begindata" line and the next
// "\begintext" (or EOF). Comment sections are dropped, so superseded example assignments parked under
// "Old values:" etc. can never be read. The kernel starts in comment mode (before the first \begindata).
var
  sl: TStringList;
  sb: TStringBuilder;
  i: Integer;
  inData: Boolean;
begin
  sl := TStringList.Create;
  sb := TStringBuilder.Create;
  try
   sl.LoadFromFile(Path);
   inData := False;
   for i := 0 to sl.Count-1 do
    if SameText(Trim(sl[i]), '\begindata') then inData := True
    else if SameText(Trim(sl[i]), '\begintext') then inData := False
    else if inData then sb.Append(sl[i]).Append(sLineBreak);
   Result := sb.ToString;
  finally
   sb.Free; sl.Free;
  end;
end;

function ParsePCKBody(const txt: string; BodyID: Int64;
  out Req, PoleRA, PoleRARate, PoleDec, PoleDecRate, PoleW, PoleWRate: Double): Boolean;
// A body's figure + orientation from an already-loaded SPICE text PCK: BODY<id>_RADII (equatorial radius =
// first value, km), _POLE_RA / _POLE_DEC (deg + deg/century rate), _PM (deg + deg/DAY rate). Only the linear
// terms are taken (nutation/precession trig series are ignored). True if the PCK carries anything for BodyID.
var pre: string; a: TArray<Double>; fmt: TFormatSettings;
begin
  Req:=0; PoleRA:=0; PoleRARate:=0; PoleDec:=0; PoleDecRate:=0; PoleW:=0; PoleWRate:=0;
  Result := False;
  fmt := TFormatSettings.Invariant;
  pre := 'BODY'+IntToStr(BodyID)+'_';
  a := PCKNums(txt, pre+'RADII', fmt);    if Length(a)>=1 then begin Req:=a[0]; Result:=True; end;
  a := PCKNums(txt, pre+'POLE_RA', fmt);  if Length(a)>=1 then begin PoleRA:=a[0];  if Length(a)>=2 then PoleRARate:=a[1];  Result:=True; end;
  a := PCKNums(txt, pre+'POLE_DEC', fmt); if Length(a)>=1 then begin PoleDec:=a[0]; if Length(a)>=2 then PoleDecRate:=a[1]; end;
  a := PCKNums(txt, pre+'PM', fmt);       if Length(a)>=1 then begin PoleW:=a[0];   if Length(a)>=2 then PoleWRate:=a[1];   end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FFiles:=nil;
  FTargets:=nil;
  FList:=nil;
  FTmin:=nil;
  FTmax:=nil;
  FExeStr:='BSPMerge v'+GetShortVersion(Application.ExeName);
  MainForm.Caption:=FExeStr;
  HorizonsMode:=(LoadStrFromIni(ChangeFileExt(Application.ExeName, '.ini'), TAG_HORIZONSMODE)='1');
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  Panel0.Width:=MainForm.ClientWidth shr 1;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if FFiles=nil then FFiles:=TStringList.Create;
  if FTargets=nil then FTargets:=TStringList.Create;
  if FList=nil then FList:=TCustomList.Create(SizeOf(Int64), 64);
  if FTmin=nil then FTmin:=TCustomList.Create(SizeOf(Double), 64);
  if FTmax=nil then FTmax:=TCustomList.Create(SizeOf(Double), 64);
end;

procedure TMainForm.CheckListBoxClick(Sender: TObject);
begin
  CheckCoverage;
end;

type
  // Downloads Default_Files to TEMP_DIR off the UI thread (so Windows doesn't flag the app as frozen).
  // Reports progress via Synchronize; TThread.Terminated is the abort flag (AbortButton -> Terminate).
  // The worker itself sets ProgressForm.ModalResult to close the modal, so the form can never close
  // mid-download and be touched by a stale Synchronize.
  TDownloadThread = class(TThread)
  private
    FHTTP: THTTPClient;
    FIdx, FTotal, FPct, FDone: Integer;
    FName, FErr, FResult: string;
    // Proxy credentials: memory-only, for this run. Never written to disk or logged -- they are the user's
    // network account, and BSPMerge has no business keeping them past the download.
    FProxyUser, FProxyPass, FProxyRealm: string;
    FProxyCancelled: Boolean;
    FLog: string;
    procedure SyncFile;
    procedure SyncProg;
    procedure SyncDone;
    procedure SyncLog;
    procedure SyncProxyPrompt;
    procedure ProxyAuth(const Sender: TObject; AnAuthTarget: TAuthTargetType; const ARealm, AURL: string;
                        var AUserName, APassword: string; var AbortAuth: Boolean; var Persistence: TAuthPersistenceType);
    procedure Recv(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
    function  GetToFile(const AURL, AFileName: string): Boolean;   // download a static kernel straight to a file
    function  GetMP(AID: Int64): Boolean;                          // generate + fetch a KBO SPK via the Horizons API
  protected
    procedure Execute; override;
  end;

function URLFileName(const U: string): string;   // the file name at the end of a URL (after the last '/', minus any query)
var i: Integer;
begin
  Result := U;
  i := Length(Result);
  while (i>0) and (Result[i]<>'/') do Dec(i);
  Result := Copy(Result, i+1, MaxInt);
  i := Pos('?', Result); if i>0 then Result := Copy(Result, 1, i-1);
end;

function PromptProxyCredentials(const ARealm: string; var AUser, APass: string): Boolean;
// Built at runtime rather than as a .dfm: it is one dialog, shown only on a 407, and keeping it here keeps the
// credentials in one place. UI thread only -- the download thread reaches it through Synchronize.
var
  F: TForm; LInfo, LU, LP: TLabel; EU, EP: TEdit; BOK, BCancel: TButton; s: string;
begin
  F := TForm.CreateNew(nil);
  try
   F.Caption := 'Proxy authentication required';
   F.BorderStyle := bsDialog;
   F.Position := poMainFormCenter;
   F.ClientWidth := 344; F.ClientHeight := 150;

   s := 'The proxy server requires a user name and password.';
   if ARealm <> '' then s := s + sLineBreak + 'Realm: ' + ARealm;
   LInfo := TLabel.Create(F); LInfo.Parent := F;
   LInfo.SetBounds(12, 10, 320, 30); LInfo.WordWrap := True; LInfo.Caption := s;

   LU := TLabel.Create(F); LU.Parent := F; LU.SetBounds(12, 55, 70, 15); LU.Caption := 'User name:';
   EU := TEdit.Create(F);  EU.Parent := F;  EU.SetBounds(90, 52, 242, 23); EU.Text := AUser;

   LP := TLabel.Create(F); LP.Parent := F; LP.SetBounds(12, 86, 70, 15); LP.Caption := 'Password:';
   EP := TEdit.Create(F);  EP.Parent := F;  EP.SetBounds(90, 83, 242, 23); EP.Text := APass;
   EP.PasswordChar := '*';

   BOK := TButton.Create(F); BOK.Parent := F; BOK.SetBounds(172, 116, 78, 25);
   BOK.Caption := 'OK'; BOK.Default := True; BOK.ModalResult := mrOk;
   BCancel := TButton.Create(F); BCancel.Parent := F; BCancel.SetBounds(256, 116, 78, 25);
   BCancel.Caption := 'Cancel'; BCancel.Cancel := True; BCancel.ModalResult := mrCancel;

   if EU.Text = '' then F.ActiveControl := EU else F.ActiveControl := EP;
   Result := F.ShowModal = mrOk;
   if Result then begin AUser := EU.Text; APass := EP.Text; end;
  finally
   F.Free;
  end;
end;

procedure TDownloadThread.SyncLog;
begin
  MainForm.Memo.Lines.Append(FLog);
end;

procedure TDownloadThread.SyncProxyPrompt;
begin
  if not PromptProxyCredentials(FProxyRealm, FProxyUser, FProxyPass) then
   begin
    FProxyCancelled := True;
    FProxyUser := ''; FProxyPass := '';
   end;
end;

procedure TDownloadThread.ProxyAuth(const Sender: TObject; AnAuthTarget: TAuthTargetType; const ARealm, AURL: string;
                                    var AUserName, APassword: string; var AbortAuth: Boolean; var Persistence: TAuthPersistenceType);
// Fires only when the proxy actually answers 407, so users without an authenticating proxy never see a thing.
// The RTL owns the whole challenge/retry dance (and picks the scheme the proxy offers -- Negotiate, NTLM,
// Digest or Basic); all it lacks is someone to ask for the credentials, which is what this callback is.
begin
  if AnAuthTarget <> TAuthTargetType.Proxy then Exit;         // 401s from the server are not ours to answer
  if FProxyCancelled then begin AbortAuth := True; Exit; end; // asked once, declined: fail the rest of the run quietly rather than nag per file
  FProxyRealm := ARealm;
  Synchronize(SyncProxyPrompt);                               // VCL is UI-thread-only; blocks until the user answers
  if FProxyCancelled then begin AbortAuth := True; Exit; end;
  AUserName := FProxyUser;
  APassword := FProxyPass;
  Persistence := TAuthPersistenceType.Client;                 // remember for this THTTPClient: one prompt per run, not one per file
end;

procedure TDownloadThread.SyncFile;
begin
  ProgressForm.ProgressLabel.Caption := Format('Downloading   %s   (%d of %d)', [FName, FIdx+1, FTotal]);
  ProgressForm.ProgressBar.Position := 0;
end;

procedure TDownloadThread.SyncProg;
begin
  ProgressForm.ProgressBar.Position := FPct;
end;

procedure TDownloadThread.SyncDone;
begin
  if Terminated then
   begin FResult := 'Download aborted by user.'; ProgressForm.ModalResult := mrAbort; end
  else if FErr<>'' then
   begin FResult := 'Download failed - '+FErr; ProgressForm.ModalResult := mrCancel; end
  else
   begin FResult := Format('Downloaded %d of %d files to %s', [FDone, FTotal, TEMP_DIR]); ProgressForm.ModalResult := mrOk; end;
end;

procedure TDownloadThread.Recv(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
var pct: Integer;
begin
  AAbort := Terminated;                                    // the HTTP client checks this to cancel the current GET
  if AContentLength>0 then pct := Round(AReadCount*100/AContentLength) else pct := 0;
  if pct<>FPct then begin FPct := pct; Synchronize(SyncProg); end;   // throttle UI updates to whole-percent changes
end;

function TDownloadThread.GetToFile(const AURL, AFileName: string): Boolean;   // a static kernel -> AFileName
var resp: IHTTPResponse; fs: TFileStream;
begin
  Result := False;
  fs := TFileStream.Create(AFileName, fmCreate);
  try
    try
      resp := FHTTP.Get(AURL, fs);
      if not Terminated then
       if resp.StatusCode = 200 then Result := True
       else FErr := Format('%s -> HTTP %d %s', [FName, resp.StatusCode, resp.StatusText]);
    except
      on E: Exception do if not Terminated then FErr := FName+': '+E.Message;
    end;
  finally
    fs.Free;
  end;
  if not Result then System.SysUtils.DeleteFile(AFileName);   // never leave a partial file behind
end;

function TDownloadThread.GetMP(AID: Int64): Boolean;
// Ask the Horizons API to build a Type 21 SPK for one small body over [EP_START, EP_STOP]; the .bsp comes
// back base64-encoded inside a JSON envelope (the "spk" field). COMMAND='DES=<spkid>;' selects it exactly (a
// bare number is read as a record index and silently resolves to the wrong object). The id is pure digits, so
// the fixed percent-encoding of the quotes/'='/';' is safe.
var resp: IHTTPResponse; ss: TStringStream; jv: TJSONValue; jo: TJSONObject; url, spk, msg, fn: string; bytes: TBytes;
begin
  Result := False;
  fn := IncludeTrailingPathDelimiter(TEMP_DIR) + FName;
  url := HORIZONS_API + '?format=json&OBJ_DATA=NO&MAKE_EPHEM=YES&EPHEM_TYPE=SPK'
       + '&START_TIME=' + EP_START + '&STOP_TIME=' + EP_STOP
       + '&COMMAND=%27DES%3D' + IntToStr(AID) + '%3B%27';   // COMMAND='DES=<id>;'
  ss := TStringStream.Create('', TEncoding.UTF8);
  try
    try
      resp := FHTTP.Get(url, ss);
      if Terminated then Exit;
      if resp.StatusCode <> 200 then begin FErr := Format('%s -> HTTP %d %s', [FName, resp.StatusCode, resp.StatusText]); Exit; end;
      jv := TJSONObject.ParseJSONValue(ss.DataString);
      if not (jv is TJSONObject) then begin FErr := FName+': malformed Horizons response'; jv.Free; Exit; end;
      jo := TJSONObject(jv);
      try
        if jo.TryGetValue<string>('spk', spk) then
         begin
          spk := StringReplace(StringReplace(spk, #13, '', [rfReplaceAll]), #10, '', [rfReplaceAll]);
          bytes := TNetEncoding.Base64.DecodeStringToBytes(spk);
          TFile.WriteAllBytes(fn, bytes);
          Result := True;
         end
        else
         begin   // Horizons reports failures in 'error' (or narrates them in 'result')
          if not jo.TryGetValue<string>('error', msg) then
           if not jo.TryGetValue<string>('result', msg) then msg := 'no SPK in response';
          FErr := Format('%s: %s', [FName, Trim(msg)]);
         end;
      finally
        jv.Free;
      end;
    except
      on E: Exception do if not Terminated then FErr := FName+': '+E.Message;
    end;
  finally
    ss.Free;
  end;
  if not Result then System.SysUtils.DeleteFile(fn);
end;

procedure TDownloadThread.Execute;
var i, idx, pxPort: Integer; fn, pxHost: string;
begin
  FDone := 0; FErr := ''; idx := 0;
  FTotal := Length(Default_Files) - Ord(MainForm.HorizonsMode) + MainForm.NumAst.Value*Ord(MainForm.HorizonsMode) + MainForm.NumKBO.Value;
  try
    ForceDirectories(TEMP_DIR);
    FHTTP := THTTPClient.Create;                           // WinHTTP-backed: native HTTPS, no OpenSSL DLLs needed
    try
      FHTTP.OnReceiveData := Recv;
      FHTTP.AuthEvent := ProxyAuth;                        // without this the RTL has no way to ask, so a 407 just fails the download
      // Pin the proxy explicitly (see GetSystemProxy): left to itself the RTL can end up going direct, which
      // behind a firewall hangs to the timeout instead of failing. Credentials are NOT set here on purpose --
      // supplying a user name up front forces Basic, whereas letting the 407 arrive lets WinHTTP negotiate
      // whatever the proxy actually offers (Negotiate/NTLM/Digest/Basic) and routes us through ProxyAuth.
      if GetSystemProxy(pxHost, pxPort) then
       begin
        FHTTP.ProxySettings := TProxySettings.Create(pxHost, pxPort);
        FLog := Format('Proxy: using the Windows setting %s:%d', [pxHost, pxPort]);
       end
      else FLog := 'Proxy: none configured in Windows - connecting directly';
      Synchronize(SyncLog);                                // log before the first request: if it hangs, this says what it was aiming at
      FHTTP.ConnectionTimeout := 30000;
      FHTTP.ResponseTimeout := 60000;                      // guards a stalled connection; resets as data flows
      // phase 1: static kernels (planets, satellites, main-belt asteroids)
      for i := 0 to High(Default_Files) - Ord(MainForm.HorizonsMode) do
       begin
        if Terminated or (FErr<>'') then Break;
        FName := URLFileName(Default_Files[i]);
        fn := IncludeTrailingPathDelimiter(TEMP_DIR) + FName;
        FIdx := idx; Inc(idx); FPct := 0; Synchronize(SyncFile);
        if FileExists(fn) then Inc(FDone)                  // already present -> skip (clear TEMP_DIR to force a refresh)
        else if GetToFile(Default_Files[i], fn) then Inc(FDone);
       end;
      // phase 2: KBO/TNO SPKs generated on demand by Horizons
      if MainForm.HorizonsMode then for i := 0 to MainForm.NumAst.Value-1 do
       begin
        if Terminated or (FErr<>'') then Break;
        FName := IntToStr(Default_Ast[i]) + '.bsp';
        fn := IncludeTrailingPathDelimiter(TEMP_DIR) + FName;
        FIdx := idx; Inc(idx); FPct := 0; Synchronize(SyncFile);
        if FileExists(fn) then Inc(FDone)
        else if GetMP(Default_Ast[i]) then Inc(FDone);
       end;
      // phase 3: KBO/TNO SPKs generated on demand by Horizons
      for i := 0 to MainForm.NumKBO.Value-1 do
       begin
        if Terminated or (FErr<>'') then Break;
        FName := IntToStr(Default_TNO[i]) + '.bsp';
        fn := IncludeTrailingPathDelimiter(TEMP_DIR) + FName;
        FIdx := idx; Inc(idx); FPct := 0; Synchronize(SyncFile);
        if FileExists(fn) then Inc(FDone)
        else if GetMP(Default_TNO[i]) then Inc(FDone);
       end;
    finally
      FHTTP.Free;
    end;
  except
    on E: Exception do FErr := E.Message;
  end;
  Synchronize(SyncDone);                                   // closes the modal ProgressForm
end;

procedure TMainForm.AbortDownloadClick(Sender: TObject);
begin
  if FDlThread<>nil then FDlThread.Terminate;              // the worker notices and closes the form itself
  ProgressForm.AbortButton.Enabled := False;
  ProgressForm.AbortButton.Caption := 'Aborting ...';
end;

procedure TMainForm.DownloadBtnClick(Sender: TObject);
var mr: TModalResult; paths: TArray<string>; i, n: Integer; totBytes: Int64; szStr: string;
begin
  if FDlThread<>nil then Exit;                             // the modal blocks re-entry, but be safe
  // Warn only when a large CORE (JPL FTP) kernel is missing -- those are the multi-GB, slow downloads. The
  // Horizons KBO SPKs are ~3.5 MB each, so a run that needs only KBOs proceeds silently. Sum the missing core
  // files (skip-if-exists), so the figure reflects exactly what will be fetched.
  totBytes:=0;
  for i:=0 to High(Default_Files) - Ord(HorizonsMode) do   // HorizonsMode skips the last (asteroid) kernel, so don't count it in the size warning
   if not FileExists(IncludeTrailingPathDelimiter(TEMP_DIR)+URLFileName(Default_Files[i])) then totBytes:=totBytes+Default_FileSizes[i];
  if totBytes>0 then
   begin
    if totBytes>=1024*1024*1024 then szStr:=Format('%.1f GB', [totBytes/(1024*1024*1024)])
    else szStr:=Format('%.0f MB', [totBytes/(1024*1024)]);
    if MessageDlg(Format('This will download about %s of ephemeris kernels to %s.'+sLineBreak+sLineBreak
                        +'The JPL planetary/satellite files are very large, so on a slow connection this can take a '
                        +'long time. Continue?', [szStr, TEMP_DIR]), mtConfirmation, [mbYes, mbNo], 0)<>mrYes then Exit;
   end;
  Memo.Lines.Append(Format('Downloading %d default files to %s ...', [Length(Default_Files) - Ord(HorizonsMode) + NumAst.Value*Ord(HorizonsMode) + NumKBO.Value, TEMP_DIR]));
  ProgressForm.AbortButton.Enabled := True;
  ProgressForm.AbortButton.Caption := '&Abort';
  ProgressForm.AbortButton.ModalResult := mrNone;         // the button only signals abort; the worker closes the form
  ProgressForm.AbortButton.OnClick := AbortDownloadClick;
  ProgressForm.ProgressBar.Max := 100;
  ProgressForm.ProgressBar.Position := 0;
  ProgressForm.ProgressLabel.Caption := 'Starting ...';
  FDlThread := TDownloadThread.Create(True);
  FDlThread.FreeOnTerminate := False;
  FDlThread.Start;
  try
    mr := ProgressForm.ShowModal;
  finally
    FDlThread.WaitFor;
    Memo.Lines.Append(TDownloadThread(FDlThread).FResult);
    FreeAndNil(FDlThread);
  end;
  if mr = mrOk then
   begin   // auto-load everything just fetched, in canonical merge order: planets+Sun, satellites, asteroids, KBOs
    SetLength(paths, Length(Default_Files) + NumAst.Value + NumKBO.Value);   // worst case (HorizonsMode): all main + NumAst + NumKBO; trimmed to n below
    n := 0;
    for i := 0 to High(Default_Files) - Ord(HorizonsMode) do
     begin
      paths[n] := IncludeTrailingPathDelimiter(TEMP_DIR)+URLFileName(Default_Files[i]);
      if FileExists(paths[n]) then Inc(n);
     end;
    if HorizonsMode then for i := 0 to NumAst.Value-1 do
     begin
      paths[n] := IncludeTrailingPathDelimiter(TEMP_DIR)+IntToStr(Default_Ast[i])+'.bsp';
      if FileExists(paths[n]) then Inc(n);
     end;
    for i := 0 to NumKBO.Value-1 do
     begin
      paths[n] := IncludeTrailingPathDelimiter(TEMP_DIR)+IntToStr(Default_TNO[i])+'.bsp';
      if FileExists(paths[n]) then Inc(n);
     end;
    SetLength(paths, n);
    LoadBSPFiles(paths);
    FilterBtnClick(nil);   // literally press Filter: uses whatever is in the NumSat/NumAst/NumKBO spin edits right now
                           // (launch defaults 0/20/4, but the user can change them before clicking Download)
   end;
end;

procedure TMainForm.FilterBtnClick(Sender: TObject);
// Uncheck CheckListBox items so each category keeps only its N most massive bodies (by BodyGM), ranked among
// the currently-CHECKED bodies. NumSat = max satellites PER PLANET, NumAst = max asteroids, NumKBO = max KBOs
// (0 = unlimited). A body (NAIF code) may own several items (different epochs/descriptors); dropping a body
// unchecks ALL of its items. Classification: asteroid/KBO by the minor-planet ranges split at number
// KBO_NUMBER_MIN; satellite by a planetary centre; planets/Sun/SSB/barycentres are never touched.
type
  TCat = (catNone, catSat, catAst, catKBO);
  TFBody = record Code, Planet: Int64; GM: Double; Cat: TCat; Keep: Boolean; end;
var
  bodies: array of TFBody;
  planets: array of Int64;
  nB, i, k, p, np, tID, cID, planet: Int64;
  dropSat, dropAst, dropKBO: Int64;
  cat: TCat;
  found: Boolean;
  s: string;

  function ExtractInt(const marker: string; out v: Int64): Boolean;   // first integer after 'marker' in s
  var a, b: Integer;
  begin
    a := Pos(marker, s); if a=0 then begin Result:=False; Exit; end;
    a := a + Length(marker); b := a; v := 0;
    while (b<=Length(s)) and (s[b]>='0') and (s[b]<='9') do begin v := v*10 + (Ord(s[b])-Ord('0')); Inc(b); end;
    Result := b>a;
  end;

  function PlanetOf(c: Int64): Int64;   // planet number 1..9 if c is a planet BC (1..9) or centre (n99), else -1
  begin
    if (c>=1) and (c<=9) then Result:=c
    else if (c>=199) and (c<=999) and (c mod 100=99) then Result:=c div 100
    else Result:=-1;
  end;

  function Classify(tg, cn: Int64; out pl: Int64): TCat;
  var num: Int64;
  begin
    pl := -1;
    if ((tg>=2000001) and (tg<=2999999)) then num := tg-2000000
    else if ((tg>=20000001) and (tg<=20999999)) then num := tg-20000000
    else num := -1;
    if num>=0 then
     begin if num<KBO_NUMBER_MIN then Result:=catAst else Result:=catKBO; Exit; end;
    pl := PlanetOf(cn);                                  // satellite: centred on a planet, and not the planet
    if (pl>=1) and (tg mod 100 <> 99) then Result:=catSat    // centre (n99) itself
    else begin Result:=catNone; pl:=-1; end;
  end;

  function FindBody(code: Int64): Int64;
  begin
    for Result:=0 to nB-1 do if bodies[Result].Code=code then Exit;
    Result:=-1;
  end;

  function RankAndMark(rcat: TCat; limit, planetFilter: Int64): Int64;
  // among bodies of rcat (and planetFilter, if >=0) sort by GM desc and mark Keep:=False past 'limit'; -> #dropped
  var idx: array of Int64; a, b, tmp: Int64;
  begin
    Result := 0;
    if limit<=0 then Exit;                               // 0 = unlimited
    SetLength(idx, 0);
    for a:=0 to nB-1 do
      if (bodies[a].Cat=rcat) and ((planetFilter<0) or (bodies[a].Planet=planetFilter)) then
       begin SetLength(idx, Length(idx)+1); idx[High(idx)]:=a; end;
    for a:=0 to High(idx)-1 do                           // selection sort by GM descending
      for b:=a+1 to High(idx) do
        if bodies[idx[b]].GM > bodies[idx[a]].GM then begin tmp:=idx[a]; idx[a]:=idx[b]; idx[b]:=tmp; end;
    for a:=limit to High(idx) do begin bodies[idx[a]].Keep:=False; Inc(Result); end;
  end;

begin
  // 1. build the unique-body database from the currently-checked, categorisable items
  nB:=0; SetLength(bodies, 0);
  for i:=0 to CheckListBox.Items.Count-1 do
    if CheckListBox.Checked[i] then
     begin
      s := FTargets[i];
      if not (ExtractInt('] (', tID) and ExtractInt(' vs (', cID)) then Continue;
      cat := Classify(tID, cID, planet);
      if (cat=catNone) or (FindBody(tID)>=0) then Continue;
      k:=nB; Inc(nB); SetLength(bodies, nB);
      bodies[k].Code:=tID; bodies[k].GM:=BodyGM(tID); bodies[k].Cat:=cat; bodies[k].Planet:=planet; bodies[k].Keep:=True;
     end;
  // 2. rank each category by mass and mark the survivors (satellites per planet)
  dropAst := RankAndMark(catAst, NumAst.Value, -1);
  dropKBO := RankAndMark(catKBO, NumKBO.Value, -1);
  dropSat := 0; SetLength(planets, 0); np:=0;
  for i:=0 to nB-1 do
    if bodies[i].Cat=catSat then
     begin
      found:=False;
      for p:=0 to np-1 do if planets[p]=bodies[i].Planet then begin found:=True; Break; end;
      if not found then begin SetLength(planets, np+1); planets[np]:=bodies[i].Planet; Inc(np); end;
     end;
  for p:=0 to np-1 do Inc(dropSat, RankAndMark(catSat, NumSat.Value, planets[p]));
  // 3. uncheck every item that belongs to a dropped body
  for i:=0 to CheckListBox.Items.Count-1 do
    if CheckListBox.Checked[i] then
     begin
      s := FTargets[i];
      if not ExtractInt('] (', tID) then Continue;
      k := FindBody(tID);
      if (k>=0) and (not bodies[k].Keep) then CheckListBox.Checked[i]:=False;
     end;
  Memo.Lines.Append(Format('Filter: dropped %d satellite(s), %d asteroid(s), %d KBO(s).',
    [dropSat, dropAst, dropKBO]));
  CheckCoverage;   // refresh the coverage caption for the (now reduced) checked set
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CheckListBox.Items.Clear;
  Memo.Lines.Clear;
  FTmax.Free; FTmax:=nil;
  FTmin.Free; FTmin:=nil;
  FList.Free; FList:=nil;
  FTargets.Free; FTargets:=nil;
  FFiles.Free; FFiles:=nil;
end;

procedure TMainForm.Panel2Resize(Sender: TObject);
begin
  CBtpc.Width:=Panel2.ClientWidth - (CBtpc.Left shl 1);
end;

procedure TMainForm.PMSelectClick(Sender: TObject);
begin
  if TMenuItem(Sender).MenuIndex=0 then CheckListBox.CheckAll(cbChecked, True, True) else CheckListBox.CheckAll(cbUnchecked, True, True);
  CheckCoverage;
end;

procedure TMainForm.LoadBSPFiles(const Paths: array of string);
// Add each .bsp in Paths (in the given order -- callers pass them pre-ordered) to the target list. Files already
// loaded, or that fail to open, are reported to the Memo and skipped. Shared by OpenBtnClick and the downloader.
var
  i, j, k, t, c, f, d: Int64;
  t0, t1: Double;
  BSPFile: TBSPFile;
  BSPXRef: TBSPXFile;
  s: string;
  z, z0: AnsiString;
begin
  BSPXRef:=TBSPXFile.Create;
  try
   for k:=0 to High(Paths) do
    try
     if FFiles.IndexOf(Paths[k])<>-1 then raise Exception.Create('File already in use: '+ExtractFileName(Paths[k]));
     if not BSPInit(@BSPFile, Paths[k]) then raise Exception.Create(BSPError);
     if not BSPSort(@BSPFile) then raise Exception.Create(BSPError);
     for i:=Low(BSPFile.TgtIdx) to BSPFile.TargetCount-1 do
      begin
       j:=BSPFile.TgtIdx[i];
       t0:=BSPFile.Rec.dsc.DESC[j].epoch0;
       t1:=BSPFile.Rec.dsc.DESC[j].epoch1;
       t:=BSPFile.Rec.dsc.DESC[j].targetID;
       c:=BSPFile.Rec.dsc.DESC[j].centerID;
       f:=BSPFile.Rec.dsc.DESC[j].refID;
       d:=BSPFile.Rec.dsc.DESC[j].typeID;
       z0:=BSPXRef.GetPerturberName(t);
       z:=BSPGetTargetName(t);
       s:=Format('[f%d d%d] (%d) %s vs (%d) %s', [f, d, t, z, c, BSPGetTargetName(c)]);
       FTargets.Append(s);
       CheckListBox.Items.Append(Format('%s - %s %s', [BSPXTimeStr(t0, 1), BSPXTimeStr(t1, 1), s]));
       CheckListBox.Checked[CheckListBox.Items.Count-1]:=(z0<>'<unknown target code>');
       FFiles.Append(BSPFile.FileName);
       FList.Append(@j);
       FTmin.Append(@t0);
       FTmax.Append(@t1);
      end;
     CheckCoverage;
    except on E: Exception do
     Memo.Lines.Append(E.Message);
    end;
  finally
   BSPXRef.Free;
  end;
end;

procedure TMainForm.OpenBtnClick(Sender: TObject);
var paths: TArray<string>; k: Integer;
begin
  Memo.Lines.Clear;
  OpenDialog.Filter:='BSP files (*.bsp)|*.bsp';
  if OpenDialog.Execute then
   begin
    SetLength(paths, OpenDialog.Files.Count);
    for k:=0 to OpenDialog.Files.Count-1 do paths[k]:=OpenDialog.Files[k];
    LoadBSPFiles(paths);
   end;
end;

procedure TMainForm.SaveDialogTypeChange(Sender: TObject);
begin
  SaveDialog.DefaultExt:=FileExt[SaveDialog.FilterIndex];
end;

function SortByKeys(List: TStringList; Index1, Index2: Integer): Integer;
var
  Value1, Value2: Integer;
begin
  Value1 := StrToInt(List.Names[Index1]);
  Value2 := StrToInt(List.Names[Index2]);
  if Value1 < Value2 then
    Result := -1
  else if Value1 > Value2 then
    Result := 1
  else
    Result := 0;
end;

procedure TMainForm.CheckCoverage;
var
  i, j: Int64;
  minT, maxT: Double;
  minS, maxS: string;
  L: TStringList;
  Tmin, Tmax: TCustomList;
begin
  L:=TStringList.Create;
  Tmin:=TCustomList.Create(SizeOf(Double), 64);
  Tmax:=TCustomList.Create(SizeOf(Double), 64);
  try
   for i:=0 to CheckListBox.Items.Count-1 do if CheckListBox.Checked[i] then
    begin
     j:=L.IndexOf(FTargets[i]);
     if j<0 then
      begin
       L.Append(FTargets[i]);
       Tmin.Append(FTmin[i]);
       Tmax.Append(FTmax[i]);
      end
      else
      begin
       if Double(FTMin[i]^)<Double(Tmin[j]^) then Double(Tmin[j]^):=Double(FTmin[i]^);
       if Double(FTMax[i]^)>Double(Tmax[j]^) then Double(Tmax[j]^):=Double(FTmax[i]^);
      end;
    end;

   minT:=NINF; maxT:=PINF;
   for i:=0 to L.Count-1 do
    begin
     if Double(Tmin[i]^)>minT then minT:=Double(Tmin[i]^);
     if Double(Tmax[i]^)<maxT then maxT:=Double(Tmax[i]^);
    end;
   if IsInfinite(minT) then minS:=FloatToStr(minT) else minS:=BSPXTimeStr(minT, 3);
   if IsInfinite(maxT) then maxS:=FloatToStr(maxT) else maxS:=BSPXTimeStr(maxT, 3);

   MainForm.Caption:=Format('%s [%s - %s]', [FExeStr, minS, maxS]);
  finally
   Tmax.Free;
   Tmin.Free;
   L.Free;
  end;
end;

{$POINTERMATH ON}   // enable PDouble indexing/arithmetic (C[k], C+n, Coef[k]) used by the re-centring below
procedure TMainForm.StartBtnClick(Sender: TObject);
var
  i, j, jj, k, p, NumTargets: Int64;
  L, TPC: TStringList;
  BSPFile: TBSPFile;
  BSPSgmRecStart: TBSPSegmentRecordStart;
  BSPXHdr: TBSPXHdr;
  BSPXDesc: array of TBSPXDesc;
  BSPXCnst: array of TBSPXBodyConst;
  Stream: TFileStream;
  FileName, s: string;
  z: AnsiString;
  Tmin, Tmax: TCustomList;
  Ep0, Ep1: Double;
  ZeroDesc: Boolean;
  Idx1, Idx2, Idx199, Idx299: Int64;
  pn: Int64;
  gmPath, hdrPath: string;
  hAU, hCL, hBETA, hGAMMA, hASUN, hJ2S, hJ3S, hJ4S, hRE, hJ2E, hJ3E, hJ4E: Double;   // Stage B: DE header overrides
  sReq, sJ2, sJ3, sJ4, sRA, sDec: Double;                                            // Stage C: satellite figure override
  pckPath, pckTxt: string;                                                           // Stage D: SPICE PCK (radii + pole + rotation)
  pReq, pRA, pRArate, pDec, pDecRate, pW, pWrate: Double;
  // heliocentric -> SSB re-centring of Sun-descendant (CenterID=10) bodies:
  SunNumCoef, SunN, SunRecBytes, SunRefID: Int64;   // SunRefID: the Sun source's SPICE frame -- must match each body we add it to
  SunInit, SunInvIntlen: Double; SunBase: PByte; SunAvail: Boolean;
  EclToICRF: TMat4D;   // ecliptical -> equatorial; the only frame conversion the merger performs
  SunBSP: TBSPFile;
  SunCache: TDictionary<Double, TArray<Double>>;
  coefBuf: TArray<Double>;
  KBOSeg: array of record Ep0, Ep1: Double; Ptr: PDouble; Len: Int64; end;   // a type-21 body's segments (cross-seam node eval)
  KBOmin, KBOmax, kbMid: Double;
  kb0, kb1, kbK, kbM, kbSeg, kbNumCoef, mpn: Int64;
  kbEp: array[0..15] of Double;   // node epochs -- must hold up to NumCoef (6 for KBOs, 11 for main-belt asteroids)
  kbState: array[0..5] of Double;
  kbSt: TState4DArray;
  function ClenshawCheb(C: PDouble; N: Int64; Tau: Double): Double;   // sum_{k} C[k]*T_k(Tau), C_0 full (SPK type-2 basis)
  var b0, b1, b2, tw: Double; k: Int64;
  begin
    b1 := 0.0; b2 := 0.0; tw := Tau + Tau;
    for k := N-1 downto 1 do begin b0 := tw*b1 - b2 + C[k]; b2 := b1; b1 := b0; end;
    Result := Tau*b1 - b2 + C[0];
  end;
  procedure SunSSB(t: Double; out X, Y, Z: Double);   // Sun's SSB position at t from the type-2 Sun source
  var recIdx: Int64; pRec: PByte; mid, rad, tau: Double; C: PDouble;
  begin
    recIdx := Trunc((t - SunInit)*SunInvIntlen);
    if recIdx < 0 then recIdx := 0 else if recIdx >= SunN then recIdx := SunN-1;
    pRec := SunBase + SunRecBytes*recIdx;              // record = [MID, RADIUS, X0..Xn, Y0..Yn, Z0..Zn]
    mid := PDouble(pRec)^; rad := PDouble(pRec+8)^;
    tau := (t - mid)/rad;
    C := PDouble(pRec + 16);
    X := ClenshawCheb(C,                 SunNumCoef, tau);
    Y := ClenshawCheb(C + SunNumCoef,    SunNumCoef, tau);
    Z := ClenshawCheb(C + 2*SunNumCoef,  SunNumCoef, tau);
  end;
  // Every 3-component body is normalised to SPICE_J2000 (ICRF) on the way out, so the .bspx is frame-uniform
  // and nothing downstream ever has to rotate. Only the two frames below can appear -- both are J2000, sharing
  // the epoch and differing only in their axes, so the conversion is purely ecliptical -> equatorial: J2000 is
  // already equatorial and needs no work, ECLIPJ2000 is one constant rotation away. Anything else we cannot
  // express, so it stops the build here.
  procedure CheckFrame(RefID, TargetID: Int64);
  begin
    if (RefID<>SPICE_J2000) and (RefID<>SPICE_ECLIPJ2000) then
     raise Exception.Create(Format('Body %d is in SPICE reference frame %d: only %d (J2000/ICRF) and %d (ECLIPJ2000) can be merged.',
                                   [TargetID, RefID, SPICE_J2000, SPICE_ECLIPJ2000]));
  end;
  // A Chebyshev fit is linear in its coefficients and the ecliptical->equatorial rotation is constant in time, so
  // rotating each coefficient triple is exactly equivalent to rotating the interpolated vector -- no re-fit,
  // no loss. Layout is component-major: NumCoef X's, then NumCoef Y's, then NumCoef Z's.
  procedure RotCoefToICRF(Coef: PDouble; NumCoef, FromRef: Int64);
  var k: Int64; V: TVec4D;
  begin
    if FromRef=SPICE_J2000 then Exit;
    for k := 0 to NumCoef-1 do
     begin
      V.X:=Coef[k]; V.Y:=Coef[NumCoef+k]; V.Z:=Coef[2*NumCoef+k]; V.W:=0.0;
      V:=V*EclToICRF;
      Coef[k]:=V.X; Coef[NumCoef+k]:=V.Y; Coef[2*NumCoef+k]:=V.Z;
     end;
  end;
  procedure AddSunToRecord(Coef: PDouble; Mid, Radius: Double; NumCoef: Int64);   // Coef += Sun's SSB (re-fit onto [Mid,Radius]), in ICRF
  var epochs: TArray<Double>; states: TState4DArray; suncoef, cached: TArray<Double>; k, tot: Int64; X, Y, Z: Double;
  begin
    tot := 3*NumCoef;
    if SunCache.TryGetValue(Mid, cached) and (Length(cached) = tot) then
     begin for k := 0 to tot-1 do Coef[k] := Coef[k] + cached[k]; Exit; end;   // memoised: same Mid across all shared-grid asteroids
    SetLength(epochs, NumCoef); SetLength(states, NumCoef); SetLength(suncoef, tot);
    ChebyshevNodeEpochs(Mid, Radius, NumCoef, @epochs[0]);
    for k := 0 to NumCoef-1 do begin SunSSB(epochs[k], X, Y, Z); states[k].R.X := X; states[k].R.Y := Y; states[k].R.Z := Z; end;
    ChebyshevEncode(states, 3, @suncoef[0]);
    RotCoefToICRF(@suncoef[0], NumCoef, SunRefID);   // callers hand us ICRF coefficients, so the Sun must be ICRF too (cache holds it rotated)
    for k := 0 to tot-1 do Coef[k] := Coef[k] + suncoef[k];
    SunCache.AddOrSetValue(Mid, Copy(suncoef, 0, tot));
  end;
begin
  EclToICRF:=GetRotMat4D(CEPS, 1.0, 0.0, 0.0);   // ecliptical -> equatorial; same constant and sense as BSPXFile's EclToICRF
  Idx1:=-1; Idx2:=-1; Idx199:=-1; Idx299:=-1;
  BSPFile.FileName:='';
  BSPFile.Stream:=nil;
  SunBSP.FileName:=''; SunBSP.Stream:=nil; SunCache:=nil;// SunAvail:=False;
  L:=TStringList.Create; TPC:=nil;
  Tmin:=TCustomList.Create(SizeOf(Double), 64);
  Tmax:=TCustomList.Create(SizeOf(Double), 64);
  Stream:=nil;
  try
   // Custom-constants mode (CBtpc): ask for the GM, oblateness (PCK) and DE-header files one at a time. Each is
   // independent -- Cancel on any one leaves that path empty and the CelestialMechanics DE440 defaults stand in
   // for that category (GMs / oblateness+radii+pole / general trailer, respectively).
   gmPath:=''; pckPath:=''; hdrPath:='';
   if CBtpc.Checked then
    begin
     OpenDialog.FileName:='';
     OpenDialog.Title:='Select the GM file (e.g. gm_de440.tpc) -- Cancel for DE440 default GMs';
     OpenDialog.Filter:='NAIF GM files (gm_*.tpc)|gm_*.tpc|Text PCK files (*.tpc)|*.tpc|All files (*.*)|*.*';
     if OpenDialog.Execute then gmPath:=OpenDialog.FileName;
     if gmPath<>'' then OpenDialog.InitialDir:=ExtractFileDir(gmPath);   // the three files usually live together
     OpenDialog.FileName:='';
     OpenDialog.Title:='Select the oblateness/PCK file (e.g. pck00011.tpc) -- Cancel for DE440 defaults';
     OpenDialog.Filter:='SPICE text PCK files (pck*.tpc)|pck*.tpc|Text PCK files (*.tpc)|*.tpc|All files (*.*)|*.*';
     if OpenDialog.Execute then pckPath:=OpenDialog.FileName;
     OpenDialog.FileName:='';
     OpenDialog.Title:='Select the DE header file (e.g. header.440t) -- Cancel for DE440 defaults';
     OpenDialog.Filter:='DE header files (header.*)|header.*|All files (*.*)|*.*';
     if OpenDialog.Execute then hdrPath:=OpenDialog.FileName;
     OpenDialog.Title:=''; OpenDialog.InitialDir:='';
    end;
   if gmPath<>'' then
    begin
     TPC:=TStringList.Create;
     TPC.LoadFromFile(gmPath);
     for i:=TPC.Count-1 downto 0 do
      begin
       SplitStr(TPC[i], '=', L);
       if L.Count<>2 then TPC.Delete(i) else
        begin
         L[0]:=TrimStr(L[0]);
         L[1]:=TrimStr(L[1]);
         if (Copy(L[0], 1, 4)<>'BODY') or (Copy(L[0], Length(L[0])-2, 3)<>'_GM') then TPC.Delete(i) else
          begin
           if (Copy(L[1], 1, 2)<>'( ') or (Copy(L[1], Length(L[1])-1, 2)<>' )') then TPC.Delete(i) else
            begin
             L[0]:=Copy(L[0], 5, Length(L[0])-7);
             if not IsInt64(L[0]) then TPC.Delete(i) else
              begin
               L[1]:=Copy(L[1], 3, Length(L[1])-4);
               L[1]:=StringReplace(L[1], 'D', 'E', [rfReplaceAll]);
               L[1]:=StringReplace(L[1], '.E', '.0E', [rfReplaceAll]);
               if not IsNum(L[1]) then TPC.Delete(i) else
               TPC[i]:=L[0]+'='+L[1];
              end;
            end;
          end;
        end;
      end;
     TPC.NameValueSeparator:='=';
     TPC.Append(Format('0=%s', [GM_SSB_STR]));
     TPC.CustomSort(SortByKeys);
     TPC.SaveToFile(ChangeFileExt(gmPath, '.txt'));
     L.Clear;
    end;

   Memo.Lines.Clear;
   for i:=0 to CheckListBox.Items.Count-1 do if CheckListBox.Checked[i] then
    begin
     j:=L.IndexOf(FTargets[i]);
     if j<0 then
      begin
       L.Append(FTargets[i]);
       Tmin.Append(FTmin[i]);
       Tmax.Append(FTmax[i]);
      end
      else
      begin
       if Double(FTMin[i]^)<Double(Tmin[j]^) then Double(Tmin[j]^):=Double(FTmin[i]^);
       if Double(FTMax[i]^)>Double(Tmax[j]^) then Double(Tmax[j]^):=Double(FTmax[i]^);
      end;
    end;
   NumTargets:=L.Count;
   if NumTargets<1 then raise Exception.Create('No targets selected.');

   Ep0:=NINF; Ep1:=PINF;
   for i:=0 to L.Count-1 do
    begin
     if Double(Tmin[i]^)>Ep0 then Ep0:=Double(Tmin[i]^);
     if Double(Tmax[i]^)<Ep1 then Ep1:=Double(Tmax[i]^);
    end;
   Tmax.Free; Tmax:=nil; Tmin.Free; Tmin:=nil; L.Free; L:=nil;
   s:=Format('Full time coverage: %s - %s', [BSPXTimeStr(Ep0, 3), BSPXTimeStr(Ep1, 3)]);
   // Uniform coverage is now ALWAYS enforced: every body is restricted to the common overlap [Ep0,Ep1] computed
   // above, so the Sun re-centring source is guaranteed to span every heliocentric body (Ep0/Ep1 are bounded by
   // the Sun's own coverage, it being one of the selected bodies). The prompt below is kept (commented out) and
   // we act as if the user always answered 'Yes'. Residual edge effect: near the very ends of the window a record's
   // half-interval (Radius) can reach a hair past the last Sun segment when the asteroid Radius exceeds the Sun's,
   // giving slightly-off values only there -- accepted per design.
   Memo.Lines.Append(s);
//   case MessageDlg(s+Chr(13)+Chr(10)+'Restrict data to this interval?', mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
//    mrYes: Memo.Lines.Append(s);
//    mrNo:  begin Ep0:=NINF; Ep1:=PINF; end;
//    else raise Exception.Create('Operation aborted by user.');
//   end;

   j:=0;
   while (j=0) and SaveDialog.Execute do
    begin
     FileName:=SaveDialog.FileName;
     if ExtractFileExt(FileName)<>FileExt[SaveDialog.FilterIndex] then FileName:=ChangeFileExt(FileName, FileExt[SaveDialog.FilterIndex]);
     if FileExists(FileName) and (MessageDlg(Format('File %s already exists, are you sure you want to overwrite it?', [ExtractFileName(FileName)]), mtConfirmation, [mbYes, mbNo], 0)<>mrYes) then raise Exception.Create('File already exists: '+ExtractFileName(FileName));

     if (SaveDialog.FilterIndex=2) and (NumTargets>25) then raise Exception.Create(Format('Too many targets selected (%d). Maximum number is 25 for a BSP output.', [NumTargets]));
     Memo.Lines.Append(Format('Targets selected: %d', [NumTargets]));
     i:=FFiles.Count;
     while (j=0) and (i>0) do
      begin
       i:=i-1;
       if FFiles[i]=FileName then j:=j+1;
      end;
     if (j>0) and (MessageDlg('File is in use, choose a different file name.', mtError, [mbOK, mbCancel], 0)=mrOK) then j:=0 else
      begin
       // preparation
       case SaveDialog.FilterIndex of
          2: begin
              // insert BSP code here
             end;
        else begin
              // BSPX mode
              SetLength(BSPXDesc, NumTargets);
              ZeroMemory(BSPXDesc, NumTargets*SizeOf(TBSPXDesc));
              ZeroMemory(@BSPXHdr, SizeOf(TBSPXHdr));
              BSPXHdr.BSPXID:=BSPX_ID;
              BSPXHdr.BSPXVer.Ver:=BSPX_VER;
              BSPXHdr.BSPXComment:='JPLConv 1.0';
              BSPXHdr.Data.Ptr:=SizeOf(TBSPXHdr);
              //BSPXHdr.Data.Size:=0; // must be filled later
              BSPXHdr.Data.Num:=NumTargets;
              BSPXHdr.Data.Len:=-1; // negative means variable record length
              //BSPXHdr.Cnst.Ptr:=0; // must be filled later (finalization)
              //BSPXHdr.Cnst.Size:=0; // must be filled later (finalization)
              BSPXHdr.Cnst.Num:=NumTargets+1;            // one const record per body + the SS-wide trailer
              BSPXHdr.Cnst.Len:=SizeOf(TBSPXBodyConst);
              //BSPXHdr.Desc.Ptr:=0; // must be filled later
              BSPXHdr.Desc.Size:=NumTargets*SizeOf(TBSPXDesc);
              BSPXHdr.Desc.Num:=NumTargets;
              BSPXHdr.Desc.Len:=SizeOf(TBSPXDesc);
              for jj:=Low(BSPXHdr.GM) to High(BSPXHdr.GM) do
               begin
                BSPXHdr.GM[jj]:=BodyGM(jj);   // authoritative DE440/441 default (CelestialMechanics.BodyConstants)
                if TPC<>nil then
                 begin
                  k:=TPC.IndexOfName(IntToStr(jj));
                  if k>=0 then BSPXHdr.GM[jj]:=StrToFloat(TPC.ValueFromIndex[k]);   // user tpc overrides
                 end;
               end;
              Stream:=TFileStream.Create(FileName, fmCreate);
              if Stream.Seek(0, soFromBeginning)<>0 then raise Exception.Create('File write error: '+ExtractFileName(FileName));
              if Stream.Write(BSPXHdr, SizeOf(TBSPXHdr))<>SizeOf(TBSPXHdr) then raise Exception.Create('File write error: '+ExtractFileName(FileName));
             end;
       end;

       // Set up the Sun (id 10, centred on the SSB, type 2) source used to re-centre heliocentric (CenterID=10)
       // bodies onto the SSB below. First matching input file is kept open for the whole build; its per-interval
       // Sun coefficients are memoised in SunCache (all shared-grid asteroids reuse them).
       if SunCache<>nil then SunCache.Free;
       SunCache := TDictionary<Double, TArray<Double>>.Create;
       if SunBSP.Stream<>nil then BSPClose(@SunBSP);
       SunAvail := False;
       for k := 0 to FFiles.Count-1 do
        begin
         if not BSPInit(@SunBSP, FFiles[k]) then Continue;
         for i := 0 to SunBSP.TargetCount-1 do
          if (SunBSP.Rec.dsc.DESC[i].targetID=10) and (SunBSP.Rec.dsc.DESC[i].centerID=0) and (SunBSP.Rec.dsc.DESC[i].typeID=2) then
           begin
            if not BSPOpen(@SunBSP) then raise Exception.Create('Cannot open Sun source file: '+FFiles[k]);
            SunInit      := SunBSP.Rec.dir[i].INIT;
            SunInvIntlen := 1.0/SunBSP.Rec.dir[i].INTLEN;
            SunN         := SunBSP.TgtRecCount[i];
            SunRecBytes  := SunBSP.TgtRecSize[i];
            SunNumCoef   := (SunRecBytes - SizeOf(TBSPSegmentRecordStart)) div (3*SizeOf(Double));
            SunBase      := PByte(SunBSP.Stream.Memory) + SunBSP.Ptr.datptr[i];
            SunRefID     := SunBSP.Rec.dsc.DESC[i].refID;
            CheckFrame(SunRefID, 10);
            SunAvail     := True;
            Memo.Lines.Append(Format('Sun re-centring source: %s  (segment #%d, %d coeffs, %d records, frame %d)', [ExtractFileName(FFiles[k]), i, SunNumCoef, SunN, SunRefID]));
            Break;
           end;
         if SunAvail then Break;
        end;
       // Fail fast: if no Sun (id 10 / centre 0 / type 2) exists in ANY input file but the selected set contains
       // heliocentric bodies (centre 10 -- Type 2 asteroids or Type 21 KBOs) that must be re-centred to the SSB,
       // there is nothing to build. The Sun comes from the input BSPs, not the output, so its own descriptor need
       // not be selected -- it only has to exist somewhere. FTargets already carries each body's centre, so this
       // needn't wait for the record loop.
       if not SunAvail then
        for j:=0 to CheckListBox.Items.Count-1 do
         if CheckListBox.Checked[j] and (Pos('vs (10) ', FTargets[j])>0) then
          raise Exception.Create('No Sun ephemeris (id 10, centre 0, type 2) is present in any input file, but the '
            +'selected set contains heliocentric bodies that must be re-centred to the SSB. Add a kernel that '
            +'contains the Sun (e.g. de440t.bsp), or deselect the heliocentric bodies.');
       jj:=-1;
       for j:=0 to FList.Count-1 do if CheckListBox.Checked[j] then
        begin
         // segment iteration
         if (BSPFile.FileName<>FFiles[j]) then
          begin
           if BSPFile.Stream<>nil then BSPClose(@BSPFile);
           if not BSPInit(@BSPFile, FFiles[j]) then raise Exception.Create('Cannot initialize file: '+FFiles[j]);
           if not BSPSort(@BSPFile) then raise Exception.Create('Cannot sort file: '+FFiles[j]);
           if not BSPOpen(@BSPFile) then raise Exception.Create('Cannot open file: '+FFiles[j]);
          end;

         i:=Int64(FList[j]^);   // absolute index

         // --- SPK Type 21 (Extended MDA; heliocentric KBO/comet SPKs): re-fit to barycentric Type 2 Chebyshev.
         // Output is a 32-day Type 2 body -- 6 coeffs for KBOs (DE440 outer-body cadence), 11 for main-belt asteroids (Mars cadence). A body's several
         // contiguous type-21 segments append into one descriptor; each output record's 6 nodes are sampled from
         // whichever segment covers that node's time (KBOSeg), so segment seams tile seamlessly.
         if (SaveDialog.FilterIndex<>2) and (BSPFile.Rec.dsc.DESC[i].typeID=21) then
          begin
           if (j<1) or (FTargets[j]<>FTargets[j-1]) then
            begin
             Memo.Lines.Append(Format('Segment started (type 21): %s', [CheckListBox.Items[j]]));
             jj:=jj+1;
             z:=BSPGetTargetName(BSPFile.Rec.dsc.DESC[i].targetID);
             MemCopy64(@z[1], @BSPXDesc[jj].TargetName, Min(Length(z), SizeOf(BSPXDesc[jj].TargetName)));
             MemCopy64(@BSPFile.Rec.sgm.SegmentID[i], @BSPXDesc[jj].TargetSrc, Min(SizeOf(BSPFile.Rec.sgm.SegmentID[i]), SizeOf(BSPXDesc[jj].TargetSrc)));
             BSPXDesc[jj].TargetID:=BSPFile.Rec.dsc.DESC[i].targetID;
             BSPXDesc[jj].CenterID:=BSPFile.Rec.dsc.DESC[i].centerID;
             if BSPXDesc[jj].CenterID=10 then BSPXDesc[jj].CenterID:=0;   // heliocentric -> SSB (re-centred below)
             BSPXDesc[jj].RefID:=BSPFile.Rec.dsc.DESC[i].refID;
             BSPXDesc[jj].TypeID:=2;                        // OUTPUT is Chebyshev type 2
             BSPXDesc[jj].NumComp:=3;
             // KBOs keep the DE440 outer-body fit (6 coeffs); main-belt asteroids (MP number < KBO_NUMBER_MIN,
             // arriving as type 21 in HorizonsMode) take Mars's DE440 fit -- 11 coeffs over the same 32 d segment.
             if (BSPXDesc[jj].TargetID>=2000001) and (BSPXDesc[jj].TargetID<=2999999) then mpn:=BSPXDesc[jj].TargetID-2000000
             else if (BSPXDesc[jj].TargetID>=20000001) and (BSPXDesc[jj].TargetID<=20999999) then mpn:=BSPXDesc[jj].TargetID-20000000
             else mpn:=-1;
             if (mpn>=0) and (mpn<KBO_NUMBER_MIN) then kbNumCoef:=11 else kbNumCoef:=6;
             BSPXDesc[jj].NumCoef:=kbNumCoef;
             BSPXDesc[jj].RecLen:=3*kbNumCoef*SizeOf(Double);   // 3 comps * NumCoef coeffs per record
             BSPXDesc[jj].ValIntv:=2764800;                 // 32 d -- DE440 outer-body cadence
             BSPXDesc[jj].Radius:=1382400;                  // 16 d
             BSPXDesc[jj].InvRadius:=1/1382400;
             BSPXDesc[jj].NumRec:=0;
             BSPXDesc[jj].DataLen:=0;
             BSPXDesc[jj].DataPtr:=Stream.Position;
             BSPXDesc[jj].T0:=PINF; BSPXDesc[jj].T1:=PINF; BSPXDesc[jj].Epoch0:=PINF; BSPXDesc[jj].Epoch1:=PINF;
             BSPXDesc[jj].GM:=BodyGM(BSPXDesc[jj].TargetID);
             if TPC<>nil then
              begin
               k:=TPC.IndexOfName(IntToStr(BSPXDesc[jj].TargetID));
               if (k<0) and (BSPXDesc[jj].TargetID>=20000001) and (BSPXDesc[jj].TargetID<=20999999) then k:=TPC.IndexOfName(IntToStr(BSPXDesc[jj].TargetID-18000000));
               if k>=0 then BSPXDesc[jj].GM:=StrToFloat(TPC.ValueFromIndex[k]);
              end;
             SetLength(KBOSeg, 0); KBOmin:=PINF; KBOmax:=NINF;   // gather this body's type-21 segments (whole file is in memory)
             for k:=0 to BSPFile.TargetCount-1 do
              if (BSPFile.Rec.dsc.DESC[k].targetID=BSPXDesc[jj].TargetID) and (BSPFile.Rec.dsc.DESC[k].typeID=21) then
               begin
                kbSeg:=Length(KBOSeg); SetLength(KBOSeg, kbSeg+1);
                KBOSeg[kbSeg].Ep0:=BSPFile.Rec.dsc.DESC[k].epoch0;
                KBOSeg[kbSeg].Ep1:=BSPFile.Rec.dsc.DESC[k].epoch1;
                KBOSeg[kbSeg].Ptr:=PDouble(PByte(BSPFile.Stream.Memory)+BSPFile.Ptr.datptr[k]);
                KBOSeg[kbSeg].Len:=Int64(BSPFile.Rec.dsc.DESC[k].idx1)-Int64(BSPFile.Rec.dsc.DESC[k].idx0)+1;
                if KBOSeg[kbSeg].Ep0<KBOmin then KBOmin:=KBOSeg[kbSeg].Ep0;
                if KBOSeg[kbSeg].Ep1>KBOmax then KBOmax:=KBOSeg[kbSeg].Ep1;
               end;
             if not SunAvail then raise Exception.Create('Cannot re-centre type 21 body '+IntToStr(BSPXDesc[jj].TargetID)+' to the SSB: no Sun (id 10, centre 0, type 2) among the inputs.');
             CheckFrame(BSPXDesc[jj].RefID, BSPXDesc[jj].TargetID);   // rotated to ICRF per record below
             SetLength(kbSt, kbNumCoef);
             if Length(coefBuf)<3*kbNumCoef then SetLength(coefBuf, 3*kbNumCoef);
            end;
           kbNumCoef:=BSPXDesc[jj].NumCoef;                 // 6 (KBO) or 11 (asteroid), fixed at this body's init
           kb0:=Ceil(KBOmin/2764800.0);                    // records whose full 32-day span lies inside the body's range
           kb1:=Floor(KBOmax/2764800.0)-1;
           for kbK:=kb0 to kb1 do
            begin
             kbMid:=kbK*2764800.0 + 1382400.0;             // (kbK+0.5)*ValIntv
             if (kbMid<BSPFile.Rec.dsc.DESC[i].epoch0) or (kbMid>=BSPFile.Rec.dsc.DESC[i].epoch1) then Continue;   // this segment owns this Mid
             if (kbMid<Ep0) or (kbMid>Ep1) then Continue;  // output time window
             ChebyshevNodeEpochs(kbMid, 1382400.0, kbNumCoef, @kbEp[0]);
             for kbM:=0 to kbNumCoef-1 do
              begin
               kbSeg:=0;                                    // segment covering this node's time (contiguous; clamp at ends)
               while (kbSeg<High(KBOSeg)) and not ((kbEp[kbM]>=KBOSeg[kbSeg].Ep0) and (kbEp[kbM]<=KBOSeg[kbSeg].Ep1)) do Inc(kbSeg);
               MDAEvalSegment(KBOSeg[kbSeg].Ptr, KBOSeg[kbSeg].Len, kbEp[kbM], @kbState[0]);
               kbSt[kbM].R.X:=kbState[0]; kbSt[kbM].R.Y:=kbState[1]; kbSt[kbM].R.Z:=kbState[2];
              end;
             ChebyshevEncode(kbSt, 3, @coefBuf[0]);         // heliocentric Chebyshev coefficients, in the source's frame
             RotCoefToICRF(@coefBuf[0], kbNumCoef, BSPXDesc[jj].RefID);   // -> ICRF, so the Sun below adds in the same frame
             AddSunToRecord(@coefBuf[0], kbMid, 1382400.0, kbNumCoef);     // += Sun SSB -> barycentric
             if Stream.Write(coefBuf[0], 3*kbNumCoef*SizeOf(Double))<>3*kbNumCoef*SizeOf(Double) then raise Exception.Create('File write error: '+ExtractFileName(FileName));
             if IsInfinite(BSPXDesc[jj].T0) then begin BSPXDesc[jj].T0:=kbMid; BSPXDesc[jj].Epoch0:=kbMid-1382400.0; end;
             BSPXDesc[jj].T1:=kbMid; BSPXDesc[jj].Epoch1:=kbMid+1382400.0;
             Inc(BSPXDesc[jj].NumRec); Inc(BSPXDesc[jj].DataLen, 3*kbNumCoef*SizeOf(Double));
            end;
           Memo.Lines.Append(Format('Copied segment #%.2d from file: %s', [i, ExtractFileName(FFiles[j])]));
           Continue;
          end;

         case SaveDialog.FilterIndex of
            2: begin
                // insert BSP code here
               end;
          else begin
                // BSPX mode
                if (j<1) or (FTargets[j]<>FTargets[j-1]) then
                 begin
                  Memo.Lines.Append(Format('Segment started: %s', [CheckListBox.Items[j]]));
                  jj:=jj+1;
                  z:=BSPGetTargetName(BSPFile.Rec.dsc.DESC[i].targetID);
                  MemCopy64(@z[1], @BSPXDesc[jj].TargetName, Min(Length(z), SizeOf(BSPXDesc[jj].TargetName)));
                  MemCopy64(@BSPFile.Rec.sgm.SegmentID[i], @BSPXDesc[jj].TargetSrc, Min(SizeOf(BSPFile.Rec.sgm.SegmentID[i]), SizeOf(BSPXDesc[jj].TargetSrc)));
                  BSPXDesc[jj].TargetID:=BSPFile.Rec.dsc.DESC[i].targetID;
                  case BSPXDesc[jj].TargetID of
                   1: Idx1:=jj;
                   2: Idx2:=jj;
                   199: Idx199:=jj;
                   299: Idx299:=jj;
                  end;

                  BSPXDesc[jj].CenterID:=BSPFile.Rec.dsc.DESC[i].centerID;
                  BSPXDesc[jj].RefID:=BSPFile.Rec.dsc.DESC[i].refID;
                  BSPXDesc[jj].TypeID:=BSPFile.Rec.dsc.DESC[i].typeID;
                  case BSPXDesc[jj].TargetID of
                   16, 1000000000, 1000000001, 1000000002: BSPXDesc[jj].NumComp:=1;
                                                       14: BSPXDesc[jj].NumComp:=2;
                                                      else BSPXDesc[jj].NumComp:=3;
                  end;
                  // RefID stays the SOURCE frame for the whole build (the record loop rotates by it, and the
                  // discontinuity check below compares against it); it is stamped to SPICE_J2000 just before the
                  // descriptors are written. Only 3-component bodies are vectors -- the angle sets (ids 14, 16,
                  // 1000000000..2) carry no frame we could rotate, so they pass through untouched.
                  if BSPXDesc[jj].NumComp=3 then CheckFrame(BSPXDesc[jj].RefID, BSPXDesc[jj].TargetID);
                  if (BSPXDesc[jj].CenterID=10) and (BSPXDesc[jj].NumComp=3) then BSPXDesc[jj].CenterID:=0;   // heliocentric -> SSB (record data re-centred below)
                  BSPXDesc[jj].RecLen:=BSPFile.TgtRecSize[i]-SizeOf(TBSPSegmentRecordStart);
                  BSPXDesc[jj].NumRec:=0;
                  //BSPXDesc[jj].NumRec:=BSPFile.TgtRecCount[i];
                  BSPXDesc[jj].DataLen:=0;
//                  BSPXDesc[jj].DataLen:=BSPXDesc[jj].NumRec*BSPXDesc[jj].RecLen;
                  BSPXDesc[jj].NumCoef:=BSPXDesc[jj].RecLen div (BSPXDesc[jj].NumComp*SizeOf(Double));
                  BSPXDesc[jj].ValIntv:=BSPFile.Rec.dir[i].INTLEN;
                  BSPXDesc[jj].Radius:=BSPFile.Rec.srs[i].RADIUS;
                  BSPXDesc[jj].InvRadius:=1/BSPFile.Rec.srs[i].RADIUS;
                 // BSPXDesc[jj].Radius:=(BSPFile.Rec.dsc.DESC[i].epoch1-BSPFile.Rec.dsc.DESC[i].epoch0)/BSPXDesc[jj].NumRec/2;

                  if (BSPXDesc[jj].TargetID=199) or (BSPXDesc[jj].TargetID=299) then
                   begin
                    BSPXDesc[jj].T0:=BSPFile.Rec.dir[i].INIT;
                    BSPXDesc[jj].T1:=BSPFile.Rec.dir[i].INIT+BSPFile.Rec.dir[i].N*BSPFile.Rec.dir[i].INTLEN;
                    BSPXDesc[jj].Epoch0:=BSPXDesc[jj].T0-BSPXDesc[jj].Radius;
                    BSPXDesc[jj].Epoch1:=BSPXDesc[jj].T1+BSPXDesc[jj].Radius;
                   end
                   else
                   begin
                    BSPXDesc[jj].T0:=PINF;
                    BSPXDesc[jj].T1:=PINF;
                    BSPXDesc[jj].Epoch0:=PINF;
                    BSPXDesc[jj].Epoch1:=PINF;
                   end;

                  BSPXDesc[jj].DataPtr:=Stream.Position;
                  BSPXDesc[jj].GM:=BodyGM(BSPXDesc[jj].TargetID);   // authoritative DE440/441 default; the table holds both 7- and 8-digit asteroid codes
                  if TPC<>nil then
                   begin
                    k:=TPC.IndexOfName(IntToStr(BSPXDesc[jj].TargetID));
                    // A user tpc overrides the default. gm_de440.tpc lists main-belt perturbers under the CLASSIC
                    // 7-digit code (2000000+n) but the kernels carry the MODERN 8-digit code (20000000+n); retry
                    // the 7-digit form so those overrides match. KBOs are already listed 8-digit.
                    if (k<0) and (BSPXDesc[jj].TargetID>=20000001) and (BSPXDesc[jj].TargetID<=20999999) then
                     k:=TPC.IndexOfName(IntToStr(BSPXDesc[jj].TargetID-18000000));
                    if k>=0 then BSPXDesc[jj].GM:=StrToFloat(TPC.ValueFromIndex[k]);   // tpc override
                   end;
                 end
                 else
                 begin
                  z:=BSPGetTargetName(BSPFile.Rec.dsc.DESC[i].targetID);
                  if CmpStr(@z[1], @BSPXDesc[jj].TargetName, Min(Length(z), SizeOf(BSPXDesc[jj].TargetName)))<>0 then raise Exception.Create('Discontinuity error (TargetName)');
                  if CmpStr(@BSPFile.Rec.sgm.SegmentID[i], @BSPXDesc[jj].TargetSrc, Min(SizeOf(BSPFile.Rec.sgm.SegmentID[i]), SizeOf(BSPXDesc[jj].TargetSrc)))<>0 then raise Exception.Create('Discontinuity error (SegmentID)');
                  if BSPFile.Rec.dsc.DESC[i].targetID<>BSPXDesc[jj].TargetID then raise Exception.Create('Discontinuity error (targetID)');
                  if BSPFile.Rec.dsc.DESC[i].centerID<>BSPXDesc[jj].CenterID then raise Exception.Create('Discontinuity error (centerID)');
                  if BSPFile.Rec.dsc.DESC[i].refID<>BSPXDesc[jj].RefID then raise Exception.Create('Discontinuity error (refID)');
                  if BSPFile.Rec.dsc.DESC[i].typeID<>BSPXDesc[jj].TypeID then raise Exception.Create('Discontinuity error (typeID)');
                  if (not IsInfinite(BSPXDesc[jj].Epoch1)) and (BSPFile.Rec.dsc.DESC[i].epoch0<>BSPXDesc[jj].Epoch1) then raise Exception.Create('Discontinuity error (t1->t0)');
                  if (not IsInfinite(BSPXDesc[jj].Epoch1)) and (BSPFile.Rec.dir[i].INIT<>BSPXDesc[jj].Epoch1) then raise Exception.Create('Discontinuity error (INIT)');
                  if BSPFile.Rec.dir[i].INTLEN<>BSPXDesc[jj].ValIntv then raise Exception.Create('Discontinuity error (INTLEN)');
                  //if BSPFile.Rec.dir[i].RSIZE<>BSPXDesc[jj].RecLen then raise Exception.Create('Discontinuity error (RSIZE)');
                  if BSPXDesc[jj].RecLen<>BSPFile.TgtRecSize[i]-SizeOf(TBSPSegmentRecordStart) then raise Exception.Create('Discontinuity error (RecLen)');
                  if BSPXDesc[jj].NumCoef<>BSPXDesc[jj].RecLen div (BSPXDesc[jj].NumComp*SizeOf(Double)) then raise Exception.Create('Discontinuity error (NumCoef)');
                  //if BSPXDesc[jj].Epoch1<>BSPFile.Rec.dsc.DESC[i].epoch0 then raise Exception.Create('Discontinuity error (t1->t0)');
                  if BSPXDesc[jj].ValIntv<>BSPFile.Rec.dir[i].INTLEN then raise Exception.Create('Discontinuity error (ValIntv)');
                  if BSPXDesc[jj].Radius<>BSPFile.Rec.srs[i].RADIUS then raise Exception.Create('Discontinuity error (Radius)');
                  //BSPXDesc[jj].Epoch1:=BSPFile.Rec.dsc.DESC[i].epoch1;
                  //BSPXDesc[jj].NumRec:=BSPXDesc[jj].NumRec+BSPFile.TgtRecCount[i];
                  //BSPXDesc[jj].DataLen:=BSPXDesc[jj].NumRec*BSPXDesc[jj].RecLen;
                  Memo.Lines.Append(Format('Segment continued: %s', [CheckListBox.Items[j]]));
                 end;
               end;
         end;

         p:=BSPFile.Ptr.datptr[i];
         if BSPFile.Stream.Seek(p, soFromBeginning)<>p then raise Exception.Create('File read error: '+ExtractFileName(BSPFile.FileName));
         for k:=0 to BSPFile.TgtRecCount[i]-1 do
          begin
           if BSPFile.Stream.Read(BSPSgmRecStart, SizeOf(TBSPSegmentRecordStart))<>SizeOf(TBSPSegmentRecordStart) then raise Exception.Create('File read error: '+ExtractFileName(BSPFile.FileName));
           if BSPSgmRecStart.RADIUS<>BSPXDesc[jj].Radius then raise Exception.Create(Format('Data discrepancy error (Radius=%g, expected=%g) in record #%d', [BSPSgmRecStart.RADIUS, BSPXDesc[jj].Radius, k]));
           ZeroDesc:=(BSPXDesc[jj].TargetID=199) or (BSPXDesc[jj].TargetID=299);
           if ZeroDesc or ((BSPSgmRecStart.MIDPOINT>=Ep0) and (BSPSgmRecStart.MIDPOINT<=Ep1)) then
            begin
             if (not ZeroDesc) and (not IsInfinite(BSPXDesc[jj].T1)) and (BSPSgmRecStart.MIDPOINT<>BSPXDesc[jj].T1+BSPXDesc[jj].ValIntv) then raise Exception.Create(Format('Data discrepancy error (MIDPOINT=%g, expected=%g) in record #%d)', [BSPSgmRecStart.MIDPOINT, BSPXDesc[jj].T1+BSPXDesc[jj].ValIntv, k]));
             // Three cases: a heliocentric body needs the Sun added (and so must reach ICRF first); an ecliptical
             // body needs only the rotation; anything already ICRF (the common case) still goes out as a raw copy.
             if (BSPXDesc[jj].NumComp=3) and ((BSPFile.Rec.dsc.DESC[i].centerID=10) or (BSPXDesc[jj].RefID<>SPICE_J2000)) then
              begin
               if (BSPFile.Rec.dsc.DESC[i].centerID=10) and (not SunAvail) then raise Exception.Create('Cannot re-centre heliocentric body '+IntToStr(BSPXDesc[jj].TargetID)+' to the SSB: no Sun (id 10, centre 0, type 2) among the selected input files.');
               if Length(coefBuf) < BSPXDesc[jj].RecLen div SizeOf(Double) then SetLength(coefBuf, BSPXDesc[jj].RecLen div SizeOf(Double));
               if BSPFile.Stream.Read(coefBuf[0], BSPXDesc[jj].RecLen)<>BSPXDesc[jj].RecLen then raise Exception.Create('File read error: '+ExtractFileName(BSPFile.FileName));
               RotCoefToICRF(@coefBuf[0], BSPXDesc[jj].NumCoef, BSPXDesc[jj].RefID);
               if BSPFile.Rec.dsc.DESC[i].centerID=10 then
                AddSunToRecord(@coefBuf[0], BSPSgmRecStart.MIDPOINT, BSPSgmRecStart.RADIUS, BSPXDesc[jj].NumCoef);   // += Sun SSB, both now ICRF
               if Stream.Write(coefBuf[0], BSPXDesc[jj].RecLen)<>BSPXDesc[jj].RecLen then raise Exception.Create('File write error: '+ExtractFileName(FileName));
              end
             else
              if Stream.CopyFrom(BSPFile.Stream, BSPXDesc[jj].RecLen)<>BSPXDesc[jj].RecLen then raise Exception.Create('Stream copy error');
             if not ZeroDesc and IsInfinite(BSPXDesc[jj].T0) then
              begin
               BSPXDesc[jj].T0:=BSPSgmRecStart.MIDPOINT;
               BSPXDesc[jj].Epoch0:=BSPXDesc[jj].T0-BSPXDesc[jj].Radius;
              end;
             BSPXDesc[jj].T1:=BSPSgmRecStart.MIDPOINT;
             BSPXDesc[jj].Epoch1:=BSPXDesc[jj].T1+BSPXDesc[jj].Radius;
             BSPXDesc[jj].NumRec:=BSPXDesc[jj].NumRec+1;
             BSPXDesc[jj].DataLen:=BSPXDesc[jj].DataLen+BSPXDesc[jj].RecLen;
            end
            else
            begin
             p:=BSPFile.Stream.Position+BSPXDesc[jj].RecLen;
             if BSPFile.Stream.Seek(BSPXDesc[jj].RecLen, soFromCurrent)<>p then raise Exception.Create('File read error: '+ExtractFileName(BSPFile.FileName));
            end;
          end;
         Memo.Lines.Append(Format('Copied segment #%.2d from file: %s', [i, ExtractFileName(FFiles[j])]));
        end;
       if (Idx1>=0) and (Idx199>=0) then
        begin
         BSPXDesc[Idx199].Epoch0:=BSPXDesc[Idx1].Epoch0;
         BSPXDesc[Idx199].Epoch1:=BSPXDesc[Idx1].Epoch1;
         BSPXDesc[Idx199].ValIntv:=BSPXDesc[Idx199].Epoch1-BSPXDesc[Idx199].Epoch0;
         BSPXDesc[Idx199].Radius:=0.5*BSPXDesc[Idx199].ValIntv;
         BSPXDesc[Idx199].InvRadius:=1/BSPXDesc[Idx199].Radius;
         BSPXDesc[Idx199].T0:=BSPXDesc[Idx199].Epoch0+BSPXDesc[Idx199].Radius;
         BSPXDesc[Idx199].T1:=BSPXDesc[Idx199].Epoch1-BSPXDesc[Idx199].Radius;
        end;
       if (Idx2>=0) and (Idx299>=0) then
        begin
         BSPXDesc[Idx299].Epoch0:=BSPXDesc[Idx2].Epoch0;
         BSPXDesc[Idx299].Epoch1:=BSPXDesc[Idx2].Epoch1;
         BSPXDesc[Idx299].ValIntv:=BSPXDesc[Idx299].Epoch1-BSPXDesc[Idx299].Epoch0;
         BSPXDesc[Idx299].Radius:=0.5*BSPXDesc[Idx299].ValIntv;
         BSPXDesc[Idx299].InvRadius:=1/BSPXDesc[Idx299].Radius;
         BSPXDesc[Idx299].T0:=BSPXDesc[Idx299].Epoch0+BSPXDesc[Idx299].Radius;
         BSPXDesc[Idx299].T1:=BSPXDesc[Idx299].Epoch1-BSPXDesc[Idx299].Radius;
        end;
       BSPXHdr.Data.Size:=Stream.Size-SizeOf(TBSPXHdr);
       BSPXHdr.Desc.Ptr:=Stream.Position;
       // Every vector body's records were rotated to ICRF as they were written, so the descriptors must now say
       // so -- up to here RefID carried the SOURCE frame, which the record loop needed. Angle sets keep theirs.
       for i:=0 to Length(BSPXDesc)-1 do if BSPXDesc[i].NumComp=3 then BSPXDesc[i].RefID:=SPICE_J2000;
       for i:=0 to Length(BSPXDesc)-1 do if Stream.Write(BSPXDesc[i], SizeOf(TBSPXDesc))<>SizeOf(TBSPXDesc) then raise Exception.Create('File write error: '+ExtractFileName(FileName));
       BSPXHdr.Desc.Size:=BSPXHdr.Desc.Num*SizeOf(TBSPXDesc);
       BSPXHdr.Cnst.Ptr:=Stream.Position;
       // Constants section: one TBSPXBodyConst per descriptor (index-matched) + a general trailer at the
       // last index. Base layer = shared defaults (SeedBodyConst from BodyConstants + DE440General trailer); the
       // descriptor GM (from the tpc) overrides the default GM per body. Later passes (header.440t /
       // satellite comments / Horizons) override Req/J/pole from the user-provided files where present.
       SetLength(BSPXCnst, NumTargets+1);
       ZeroMemory(BSPXCnst, (NumTargets+1)*SizeOf(TBSPXBodyConst));
       for i:=0 to NumTargets-1 do
        begin
         SeedBodyConst(BSPXDesc[i].TargetID, BSPXCnst[i]);              // per-body defaults (GM + figure) from BodyConstants
         if BSPXDesc[i].GM<>0.0 then BSPXCnst[i].GM:=BSPXDesc[i].GM;    // tpc GM overrides the default
        end;
       BSPXCnst[NumTargets]:=DE440General;
       if BSPXHdr.GM[High(BSPXHdr.GM)]<>0.0 then BSPXCnst[NumTargets].GMS:=BSPXHdr.GM[High(BSPXHdr.GM)];
       // Stage B: override the general trailer (AU/CLIGHT/BETA/GAMMA) + Sun/Earth oblateness from the
       // user-selected DE header (header.4xx) -- so a build from a non-DE440 release uses its own values.
       // GM/GMS stay from the tpc (the header's GM's are AU^3/day^2); POLTIM stays the seeded J2000.
       if (hdrPath<>'') and ParseDEHeaderConsts(hdrPath, hAU,hCL,hBETA,hGAMMA,hASUN,hJ2S,hJ3S,hJ4S,hRE,hJ2E,hJ3E,hJ4E) then
        begin
         if not IsNaN(hAU)    then BSPXCnst[NumTargets].AU:=hAU;
         if not IsNaN(hCL)    then BSPXCnst[NumTargets].CLIGHT:=hCL;
         if not IsNaN(hBETA)  then BSPXCnst[NumTargets].BETA:=hBETA;
         if not IsNaN(hGAMMA) then BSPXCnst[NumTargets].GAMMA:=hGAMMA;
         k:=IdxOfTarget(BSPXDesc, 10);    // Sun
         if k>=0 then begin if not IsNaN(hASUN) then BSPXCnst[k].Req:=hASUN; if not IsNaN(hJ2S) then BSPXCnst[k].J2:=hJ2S;
                            if not IsNaN(hJ3S) then BSPXCnst[k].J3:=hJ3S;   if not IsNaN(hJ4S) then BSPXCnst[k].J4:=hJ4S; end;
         k:=IdxOfTarget(BSPXDesc, 399);   // Earth
         if k>=0 then begin if not IsNaN(hRE) then BSPXCnst[k].Req:=hRE;   if not IsNaN(hJ2E) then BSPXCnst[k].J2:=hJ2E;
                            if not IsNaN(hJ3E) then BSPXCnst[k].J3:=hJ3E;   if not IsNaN(hJ4E) then BSPXCnst[k].J4:=hJ4E; end;
        end;
       if gmPath='' then Memo.Lines.Append('No GM file selected -- default DE440 GMs used.')
       else Memo.Lines.Append('GM values applied from: '+ExtractFileName(gmPath));
       if hdrPath='' then Memo.Lines.Append('No DE header file selected -- general constants (AU/CLIGHT/BETA/GAMMA, Sun/Earth figures) from DE440 defaults.')
       else Memo.Lines.Append('DE header constants applied from: '+ExtractFileName(hdrPath));
       // Stage C: override each giant planet's Req/J/pole from its satellite BSP comment block (any selected
       // source file whose comment carries a J{n}02). Planet centre id = pn*100+99 (499/599/699/799/899).
       for j:=0 to FList.Count-1 do if CheckListBox.Checked[j] then
        for pn:=4 to 8 do
         if ParseSatelliteFigure(FFiles[j], pn, sReq,sJ2,sJ3,sJ4,sRA,sDec) then
          begin
           k:=IdxOfTarget(BSPXDesc, pn*100+99);
           if k>=0 then
            begin
             if sReq<>0.0 then BSPXCnst[k].Req:=sReq;
             BSPXCnst[k].J2:=sJ2; BSPXCnst[k].J3:=sJ3; BSPXCnst[k].J4:=sJ4;
             BSPXCnst[k].PoleRA:=sRA; BSPXCnst[k].PoleDec:=sDec;
            end;
          end;
       // Stage D: SPICE text PCK (the user-selected pck*.tpc) -- the canonical source for body RADII + pole
       // orientation + rotation. Fills radius + J2000 pole for bodies the DE files don't cover (moons/dwarfs)
       // WITHOUT overwriting the DE-consistent planet figures (their Req/pole must match the J2 term), and
       // supplies pole rates + the prime-meridian rotation W (deg/day) for ALL bodies -- the DE source has none.
       if pckPath<>'' then
        begin
         pckTxt := PCKDataOnly(pckPath);   // data sections only -- ignore commented "Old values" assignments
         for i:=0 to NumTargets-1 do
          if ParsePCKBody(pckTxt, BSPXDesc[i].TargetID, pReq,pRA,pRArate,pDec,pDecRate,pW,pWrate) then
           begin
            if BSPXCnst[i].Req=0.0 then   // uncovered body (moon/dwarf): take radius + J2000 pole from the PCK
             begin BSPXCnst[i].Req:=pReq; BSPXCnst[i].PoleRA:=pRA; BSPXCnst[i].PoleDec:=pDec; end;
            BSPXCnst[i].PoleRARate:=pRArate; BSPXCnst[i].PoleDecRate:=pDecRate;   // rates + spin always from the PCK
            BSPXCnst[i].PoleW:=pW; BSPXCnst[i].PoleWRate:=pWrate;
           end;
         Memo.Lines.Append('PCK figures applied from: '+ExtractFileName(pckPath));
        end
       else Memo.Lines.Append('No oblateness/PCK file selected -- satellite radii/poles from DE440 defaults.');
       for i:=0 to NumTargets do if Stream.Write(BSPXCnst[i], SizeOf(TBSPXBodyConst))<>SizeOf(TBSPXBodyConst) then raise Exception.Create('File write error: '+ExtractFileName(FileName));
       BSPXHdr.Cnst.Num:=NumTargets+1;
       BSPXHdr.Cnst.Size:=BSPXHdr.Cnst.Num*SizeOf(TBSPXBodyConst);
       BSPXHdr.FileSize:=Stream.Size;
       if Stream.Seek(0, soFromBeginning)<>0 then raise Exception.Create('File write error: '+ExtractFileName(FileName));
       if Stream.Write(BSPXHdr, SizeOf(TBSPXHdr))<>SizeOf(TBSPXHdr) then raise Exception.Create('File write error: '+ExtractFileName(FileName));
       p:=0;
       for i:=0 to NumTargets-1 do if BSPXDesc[i].GM<>0.0 then Inc(p);
       Memo.Lines.Append(Format('%d descriptors written, %d of them valid perturbers (nonzero GM).', [NumTargets, p]));
       Memo.Lines.Append('Data saved to file: '+FileName);
       j:=1;
      end;
    end;
  except on E: Exception do
   begin
    Memo.Lines.Append(E.Message);
    if Stream<>nil then   // the output file was created but the build did not finish -- drop the incomplete file
     begin FreeAndNil(Stream); System.SysUtils.DeleteFile(FileName); Memo.Lines.Append('Incomplete output file deleted: '+ExtractFileName(FileName)); end;
   end;
  end;
  if Stream<>nil then Stream.Free;
  if Tmax<>nil then Tmax.Free;
  if Tmin<>nil then Tmin.Free;
  if L<>nil then L.Free;
  if TPC<>nil then TPC.Free;
  if SunBSP.Stream<>nil then BSPClose(@SunBSP);
  if SunCache<>nil then SunCache.Free;
  if BSPFile.Stream<>nil then BSPClose(@BSPFile);
  SetLength(BSPXDesc, 0);
  SetLength(BSPXCnst, 0);
end;
end.
