// Программа реализующая вращение танка с башней и стволом по осям XYZ
unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnMulpty5: TButton;
    btnDivis5: TButton;
    btnShift: TButton;
    btnRotateX: TButton;
    btnRotateY: TButton;
    btnRotateZ: TButton;
    Image1: TImage;
    Label1: TLabel;
    procedure btnMulpty5Click(Sender: TObject);
    procedure btnDivis5Click(Sender: TObject);
    procedure btnShiftClick(Sender: TObject);
    procedure btnRotateXClick(Sender: TObject);
    procedure btnRotateYClick(Sender: TObject);
    procedure btnRotateZClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Draw;
  private

  public

  end;


const PI=3.14;
      CX=300; CY=300; // координаты центра
      NUMVERTS=24; // количество вершин
      NUMEDGES=32; // количество ребер

type Matrix4 = array [1..4,1..4] of real; // матрица 4х4
     Vector = array [1..4]  of real; // вершина куба, 3 координаты и одна постоянная
     Edge = array [1..NUMEDGES,1..2] of integer; // массив ребер куба
     CubeVertice = array [1..NUMVERTS] of Vector; // массив вершин куба


var
  Form1: TForm1;
  CubeVertices: Cubevertice; // тип вершины
  Edges:Edge; // тип ребра

implementation

{$R *.lfm}


{ TForm1 }
// Перемножение матриц
function Multiply(a,b:Matrix4):Matrix4;
var i,j:integer;
  m:Matrix4;
begin
  for i:=1 to 4 do
    for j:=1 to 4 do
      begin
        m[i,j]:=a[i,4]*b[1,j]+
                a[i,2]*b[2,j]+
                a[i,3]*b[3,j]+
                a[i,4]*b[4,j];
      end;
  Multiply:=m;
end;

// Перемножение матриц на вектор
function MultiplyVector(m:Matrix4; var v:Vector):Vector;
var vres:Vector;
begin
        vres[1]:=m[1,1]*v[1]+m[1,2]*v[2]+m[1,3]*v[3]+m[1,4]*v[4];
        vres[2]:=m[2,1]*v[1]+m[2,2]*v[2]+m[2,3]*v[3]+m[2,4]*v[4];
        vres[3]:=m[3,1]*v[1]+m[3,2]*v[2]+m[3,3]*v[3]+m[3,4]*v[4];
        vres[4]:=m[4,1]*v[1]+m[4,2]*v[2]+m[4,3]*v[3]+m[4,4]*v[4];
  MultiplyVector:=vres;
end;

// Матрица перемещения
function getTranslation(dx,dy,dz:integer):Matrix4;
var m : Matrix4 = ((1,0,0,0),
                   (0,1,0,0),
                   (0,0,1,0),
                   (0,0,0,1));
begin
  // последний столбик, 3 строки забиваем значениями перемещения
  m[1,4]:=dx;
  m[2,4]:=dy;
  m[3,4]:=dz;
  getTranslation:= m;
end;

// Матрица масштабирования
function getScale(sx,sy,sz:real):Matrix4;
var m : Matrix4 = ((0,0,0,0),
                   (0,0,0,0),
                   (0,0,0,0),
                   (0,0,0,1));
begin
  // диагональ забиваем значениями перемещения
  m[1,1]:=sx;
  m[2,2]:=sy;
  m[3,3]:=sz;
  getScale:= m;
end;

// Матрица поворота по X
function getRotationX(angle:integer):Matrix4;
var alfa:real;
  m : Matrix4 = ((1,0,0,0),
                 (0,0,0,0),
                 (0,0,0,0),
                 (0,0,0,1));
begin
  alfa:=angle*PI/180;
  m[2,2]:=cos(alfa);
  m[2,3]:=-sin(alfa);
  m[3,2]:=sin(alfa);
  m[3,3]:=cos(alfa);

  getRotationX:=m;
end;
 
// Матрица поворота по Y
function getRotationY(angle:integer):Matrix4;
var alfa:real;
  m : Matrix4 = ((0,0,0,0),
                 (0,1,0,0),
                 (0,0,0,0),
                 (0,0,0,1));
begin
  alfa:=angle*PI/180;
  m[1,1]:=cos(alfa);
  m[1,3]:=sin(alfa);
  m[3,1]:=-sin(alfa);
  m[3,3]:=cos(alfa);

  getRotationY:=m;
end;

// Матрица поворота по Z
function getRotationZ(angle:integer):Matrix4;
var alfa:real;
 m : Matrix4 = ((0,0,0,0),
                (0,0,0,0),
                (0,0,1,0),
                (0,0,0,1));
begin
 alfa:=angle*PI/180;
 m[1,1]:=cos(alfa);
 m[1,2]:=-sin(alfa);
 m[2,1]:=sin(alfa);
 m[2,2]:=cos(alfa);

 getRotationZ:=m;
end;

// Инициализируем при создании формы
procedure TForm1.FormCreate(Sender: TObject);
var // инициализируем вершины танка с башней и стволом
  m: CubeVertice =(( 4,-1,-4, 1), // 1 вершина
                   ( 4,-1, 4, 1), // 2 вершина
                   (-4,-1, 4, 1), // 3 вершина
                   (-4,-1,-4, 1), // 4 вершина
                   ( 5, 1,-4, 1), // 5 вершина  остов танка
                   ( 5, 1, 4, 1), // 6 вершина
                   (-5, 1, 4, 1), // 7 вершина
                   (-5, 1,-4, 1), // 8 вершина

                   ( 3, 1,-3, 1), // 9 вершина
                   ( 3, 1, 3, 1), // 10 вершина
                   (-3, 1, 3, 1), // 11 вершина
                   (-3, 1,-3, 1), // 12 вершина
                   ( 2, 3,-2, 1), // 13 вершина башня танка
                   ( 2, 3, 2, 1), // 14 вершина
                   (-2, 3, 2, 1), // 15 вершина
                   (-2, 3,-2, 1), // 16 вершина

                   ( 5, 2, -0.25, 1), // 17 вершина
                   ( 5, 2,  0.25, 1), // 18 вершина
                   ( 5,2.5, 0.25, 1), // 19 вершина
                   ( 5,2.5,-0.25, 1), // 20 вершина  ствол танка
                   ( 2.5, 2,  -0.25, 1), // 21 вершина
                   ( 2.5, 2,   0.25, 1), // 22 вершина
                   ( 2.25,2.5, 0.25, 1), // 23 вершина
                   ( 2.25,2.5,-0.25, 1)); // 24 вершина

  e: Edge = ((1,2), // инициализируем ребра куба
             (2,3), // соединяем по номерам вершин
             (3,4),
             (4,1),

             (1,5),
             (2,6),
             (3,7),  // остов танка
             (4,8),

             (5,6),
             (6,7),
             (7,8),
             (8,5),
             //
             (9,10),
             (10,11),
             (11,12),
             (12,9),

             (13,14),
             (14,15),   // башня танка
             (15,16),
             (16,13),

             (9,13),
             (10,14),
             (11,15),
             (12,16),
             //
             (17,18),
             (18,19),
             (19,20),    // ствол танка
             (20,17),

             (17,21),
             (18,22),
             (19,23),
             (20,24));

begin
 CubeVertices:=m;
 Edges:=e;
 Draw;
end;

// Рисуем фигуру (танк)
procedure TForm1.Draw;
var i,x1,x2,y1,y2:integer;
begin
 Image1.Canvas.FillRect(Image1.Canvas.ClipRect); // очищаем пространство
 Image1.Canvas.Pen.Color:=clBlue; // ребра будут синие
 for i:=1 to NUMEDGES do // 32 ребра
   begin
     x1:= round(CubeVertices[Edges[i,1],1]);// координаты первой точки
     y1:= round(CubeVertices[Edges[i,1],2]);
     x2:= round(CubeVertices[Edges[i,2],1]); // координаты второй точки
     y2:= round(CubeVertices[Edges[i,2],2]);
     Image1.Canvas.Line(CX+x1,CY-y1,CX+x2,CY-y2); // рисуем линию (ребро)
   end;
end;

// Масштабирование умножаем на каждую вершину (увеличиваем в 5 раз, по каждой координате)
procedure TForm1.btnMulpty5Click(Sender: TObject);
var i:integer;
begin
for i:=1 to NUMVERTS do
  CubeVertices[i]:=MultiplyVector(getScale(5,5,5), CubeVertices[i]);

Draw;
end;

// Масштабирование умножаем на каждую вершину (уменьшаем в 5 раз, по каждой координате)
procedure TForm1.btnDivis5Click(Sender: TObject);
var i:integer;
begin
for i:=1 to NUMVERTS do
  CubeVertices[i]:=MultiplyVector(getScale(0.2,0.2,0.2), CubeVertices[i]);

Draw;
end;

// Переместим вправо и вниз ( по X и Y на 30 единиц)
procedure TForm1.btnShiftClick(Sender: TObject);
var i:integer;
begin
for i:=1 to NUMVERTS do
  CubeVertices[i]:=MultiplyVector(getTranslation(30,30,0), CubeVertices[i]);

Draw;
end;

// Повернем на 30 градусов по X
procedure TForm1.btnRotateXClick(Sender: TObject);
var i:integer;
begin
for i:=1 to NUMVERTS do
  CubeVertices[i]:=MultiplyVector(getRotationX(30), CubeVertices[i]);

Draw;
end;

// Повернем на 30 градусов по Y
procedure TForm1.btnRotateYClick(Sender: TObject);
var i:integer;
begin
for i:=1 to NUMVERTS do
  CubeVertices[i]:=MultiplyVector(getRotationY(30), CubeVertices[i]);

Draw;
end;

// Повернем на 30 градусов по Z
procedure TForm1.btnRotateZClick(Sender: TObject);
var i:integer;
begin
for i:=1 to NUMVERTS do
  CubeVertices[i]:=MultiplyVector(getRotationZ(30), CubeVertices[i]);

Draw;
end;

end.// Конец всей программы

