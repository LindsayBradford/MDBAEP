(*unit Nodes;

interface
uses
    array_t;

type
    imagesqr = record
          x1,y1 : longint;
    end;

    DimensionData = record
          Links : longint;
    end;

    Linkage = class;

    Node = class
    public
          Links : array_t; {Of linkages}
          data : variant;  {The Data position - often data will be stored here}

          Ancestor : Linkage;{The linkage to the node that 'inspired' 'this' one}

          Radius : longint;

          constructor create;
          constructor createNull;
          constructor createLinked(lLinks : longint);
          constructor createsized(lLinks,size : longint);
          constructor createtyped(lLinks : longint; sztype : string);
          destructor destroy;
          destructor dest;
          procedure free;

          function RtnRefNum : longint;  {Returns the private NodeRefNum}
          function RtnValue : variant;
          function TestNodeN(N : longint) : boolean;

          function rtnAncestorNode : Node; virtual;
          function rtnNodeN(N : longint) : Node; virtual;
          procedure SetNodeN(N : longint; const tmpNode : node); virtual;

          function activelinks : longint;
          function pathref : longint;
          procedure followLinkN(N : integer);

          procedure drawimage(var Ref : longint);
          procedure drawlinkages;

          procedure setradius(rad : longint);


          procedure image(ref : imagesqr); dynamic;
          procedure imageLinks(ref1,ref2 : imagesqr);
          procedure imageLable(ref1,ref2 : imagesqr; Value : longint);

          function asString : string; dynamic; abstract;

    protected
    private
          NodeRefNum : longint; {A simple reference}
          ActiveImageRef : longint;

          function derivedimage(ref : longint) : imagesqr;  dynamic;
          function derivedlinkage(ref : longint) : imagesqr; dynamic;
          function DataAsString : string;
    end;

    Linkage = class
    public
          ptrToNode : Node;     {The node pointed to by the linkage}
          ref : integer;         {A reference - not being used at the moment}

          constructor create;
          destructor destroy;
          procedure free;

          function rtnNode : Node;
    end;

    SpecialNode = class(Node)

    end;

    GenericNode = class(Node)
    public
          Data : pointer;           {A generic node is a pointer to a }
          lDataSize : longint;      {sized memory field}

          constructor create(lLinks,lsize : longint);
          destructor destroy;
          procedure free;

    end;

    TypedNode = class(Node)         {A temporary blank object}
    public
          constructor create(lLinks : longint);
          destructor destroy;
          procedure free;

    end;

    LongintNode = class(TypedNode)
    public
          Data : longint;           {A true typed Node}

          constructor create(lLinks : longint);
          destructor destroy;
          procedure free;

    end;

    RealNode = class(TypedNode)
    public
          Data : real;              {A true typed Node}

          constructor create(lLinks : longint);
          destructor destroy;
          procedure free;

    end;

    ObjectNode = class(TypedNode)
    public
          Data : tObject;           {A true typed Node}

          constructor create(lLinks : longint);
          destructor destroy;
          procedure free;

    end;

    FractalNode = class(TypedNode)
    public
          Field : TwoDimData;

          SingleValue : longint;
          Variance : longint;

          constructor create(Dimension : DimensionData);
          destructor destroy;
          procedure free;
    private
          function derivedimage(ref : longint) : imagesqr; override;
          function derivedlinkage(ref : longint) : imagesqr; override;
    end;

var
   twoDimensions : DimensionData;

implementation
*)

uses
    graphics,{tester,}dscanvas,dialogs,sysutils;

const
   baseradius = 25;

type
    viewer = array[1..100] of longint;
    
var
   NodeMarker : longint;  {A means of assigning a discret value to each node}
   LinkageRef : longint; {The linkage ref counter}


function Node.activeLinks : longint;
var
   x : longint;
   l : linkage;
begin
     result := 0;
     for x := 1 to Links.lMaxSize do
     begin
          links.rtnValue(x,@l);
          if l.ptrtonode <> nil then inc(Result);
     end;
end;

constructor FractalNode.create(Dimension : DimensionData);
begin
     inherited create(Dimension.links);

     Field := TwoDimData.create;
     SingleValue := -1;
     Variance := -1;
end;

destructor FractalNode.Destroy;
begin
     if self <> nil then Field.destroy;

     inherited destroy;
end;

procedure FractalNode.Free;
begin
     inherited free;
end;

constructor Linkage.create;
begin
     inherited create;
     ptrToNode := Nil;
     ref := LinkageRef;
     inc(linkageRef);
end;

destructor Linkage.destroy;
begin
     if self <> nil then
     begin
          if ptrToNode <> nil then
          begin
               ptrToNode.Ancestor := nil;
               ptrToNode.destroy;
          end;
          inherited destroy;
     end;
end;

procedure Linkage.Free;
begin
     if ptrToNode <> NIL then
     begin
          ptrToNode.free;
          ptrToNode := NIL;
     inherited free;
     end;

end;

function Linkage.rtnNode : Node;
begin
     Result := ptrToNode;
end;


constructor Node.create;
begin
     inherited create;

     Links := array_t.create;
     Ancestor := Linkage.create;

     Radius := BaseRadius;
     NodeRefNum := NodeMarker;
     inc(NodeMarker);

end;

constructor Node.createNull;
begin
     inherited create;
end;

constructor Node.createLinked(lLinks : longint);
var
   x : longint;
   tempLinkage : linkage;

begin
     create;

     Links.init(sizeof(linkage),lLinks);
     for x := 1 to lLinks do
     begin
          Links.rtnValue(x,@tempLinkage);
          tempLinkage := Linkage.create;
          Links.setValue(x,@TempLinkage);
     end;
     TempLinkage := nil;

end;

constructor Node.createsized(lLinks,size : longint);
begin
     createLinked(lLinks);

     Radius := BaseRadius;

end;

constructor Node.createtyped(lLinks : longint; szType : string);
begin
     createLinked(lLinks);

     Radius := BaseRadius;

end;

destructor Node.destroy;
var
   x : longint;
   tempLinkage : linkage;

begin
     if self <> nil then
     begin
{          Ancestor := nil;
          if Ancestor <> nil then }
          if links <> nil then
          begin
               if Links.ptrDataStart <> nil then
                  for x := 1 to Links.lMaxSize do
                  begin
                       Links.rtnValue(x,@tempLinkage);
                       tempLinkage.destroy;
                       tempLinkage := Nil;
                       Links.setValue(x,@tempLinkage);
                  end;

               Links.destroy;
               Links := Nil;
          end;
          {Remove Linkage from ancestor}
          if Ancestor.ptrToNode <> nil then
          begin
               {From the node that points to this one - find the app ref link
                and set it to nil}
               for x := 1 to Ancestor.ptrToNode.Links.lMaxSize do
               begin
                    Ancestor.ptrToNode.Links.rtnValue(x,@tempLinkage);
                    if tempLinkage.ptrToNode = self then
                    begin
                         tempLinkage.ptrToNode := nil;
                         Ancestor.ptrToNode.Links.setValue(x,@tempLinkage);
                         break;
                    end;
               end;
               Ancestor.ptrToNode := nil;
          end;
          Ancestor.destroy;
          Ancestor := Nil;

          inherited destroy;
     end
     else
         inherited destroy;
end;

function Node.TestNodeN(N : longint) : boolean;
var
   x : longint;
begin
     Links.rtnValue(N,@x);
     if x = 0 then
     begin
          result := FALSE;
     end
     else
     begin
          result := TRUE;
     end;
end;

destructor Node.dest;
begin
     Links.destroy;
     Links.ptrDataStart := Nil;

     Links := Nil;
     inherited destroy;
end;

procedure Node.Free;
var
   x : longint;
   tempLinkage : linkage;

begin
     if Links.ptrDataStart <> nil then
     for x := 1 to Links.lMaxSize do
     begin
          Links.rtnValue(x,@tempLinkage);
          tempLinkage.free;
     end;
     links.free;
     if Ancestor.ptrToNode <> nil then
     for x := 1 to Ancestor.ptrToNode.links.lmaxsize do
     begin
          Ancestor.ptrToNode.links.rtnValue(x,@tempLinkage);
          if tempLinkage.ptrToNode = self then
          begin
               tempLinkage.ptrToNode := nil;
               tempLinkage.free;
               tempLinkage.ptrToNode := nil;
               Ancestor.ptrToNode.links.setValue(x,@tempLinkage);
          end;
     end;

     Ancestor.ptrToNode := Nil;
     Ancestor.free;
     inherited free;
end;

procedure node.setradius(rad : longint);
begin
     radius := rad;
end;

function Node.rtnAncestorNode : Node;
begin
     Result := Ancestor.rtnNode;
end;

function Node.rtnNodeN(N : longint) : Node;
var
   ActiveLink : Linkage;
begin
{     ActiveLink := Linkage.create;}
     Links.rtnValue(N,@ActiveLink);

     Result := ActiveLink.ptrToNode;

{     ActiveLink.free;}
end;

procedure Node.SetNodeN(N : longint; const tmpNode : node);
var
   ActiveLink : Linkage;
begin
{     ActiveLink := Linkage.create;}
     Links.rtnValue(N,@ActiveLink);
     ActiveLink.ptrToNode := tmpNode;

{     Links.setValue(N,ActiveLink);}

{     tmpNode.Ancestor.ptrToNode := self;}

end;

procedure Node.followLinkN(N : integer);
begin
     if ((N > 0) and (N <= Links.lMaxSize)) then
        self := rtnNodeN(N)
     else
        if N = 1 then
           self := rtnAncestorNode
        else
           if N <> 0 then
           begin
                messagedlg('Cannot follow a link of '+inttostr(N),mterror,[mbok],0);
           end;
end;

function Node.RtnValue : variant;
begin
     result := data;
end;

function Node.rtnRefNum : longint;
begin
     Result := NodeRefNum;
end;

function Node.DataAsString : string;
begin
     result := string(data);
end;

procedure Node.image(ref : imagesqr);
{Draws ellipse and writes data}
begin
     DrawCircle(ref.x1,ref.y1,radius);
     writeText(ref.x1-radius div 4,ref.y1-radius div 3,dataasstring);
end;

function Node.pathref : longint;
var
   tmpNode : Node;
   tmpNode2 : Node;
   x : longint;

begin
     result := 0;
     tmpNode := rtnAncestorNode;
     if tmpNode <> nil then
     begin
          for x := 1 to tmpNode.Links.lmaxsize do
          begin
               tmpNode2 := tmpNode.rtnNodeN(x);
               if tmpNode2 = self then
               begin
                    result := x;
                    exit;
               end;
          end;
     end;

end;

procedure Node.imageLinks(ref1,ref2 : imagesqr);
begin
{     drawArc(ref1.x1,ref1.y1,ref2.x1,ref2.y1);}
     form2.Canvas.moveto(ref1.x1,ref1.y1-radius);
     form2.canvas.LineTo(ref2.x1,ref2.y1);
end;

procedure Node.imageLable(ref1,ref2 : imagesqr; Value : longint);
begin
     form2.Canvas.textout(((ref1.x1+ref2.x1) div 2),((ref1.y1+ref2.y1) div 2),inttostr(Value));
end;

procedure Node.drawimage(var Ref : longint);
{Draws the image of the Node

   Set ActiveImageRef to TrueImageRef
   inc(TrueImageRef)
   image(derivedimage(ActiveImageRef))
}
begin
     ActiveImageRef := Ref;
     inc(Ref);
     image(derivedimage(ActiveImageRef));
end;


procedure Node.drawlinkages;
{ Save initial colour
set colour to black
drawforward linkages
set colour to red
draw ancestor linkage
set colour to initial colour
}
procedure linkup(tmp1,tmp2 : imagesqr);
begin
     drawArc(tmp1.x1,tmp1.y1,tmp2.x1,tmp2.y1);
end;

procedure drawforwardlinkages;
var
   tmplink : linkage;
   x : longint;

begin
     for x := 1 to links.lmaxsize do
     begin
          links.rtnValue(x,@tmpLink);
          if tmpLink.ptrToNode <> nil then
             linkUp(derivedLinkage(ActiveImageRef),
                    derivedLinkage(tmpLink.ptrToNode.ActiveImageRef));
     end;
end;

procedure drawancestorlinkage;
begin
     if Ancestor.ptrToNode <> nil then
        linkup(derivedLinkage(ActiveImageRef),
               derivedLinkage(Ancestor.ptrToNode.ActiveImageRef));
end;

begin
     form2.canvas.pen.color := clBlack;
     drawforwardlinkages;
     form2.canvas.pen.color := clRed;
     drawancestorlinkage;
     form2.canvas.pen.color := clBlack;
end;

function Node.derivedimage(ref : longint) : imagesqr;
{ Returns the 2 coords of the centre of the image

}
begin
     result.x1 := (ref+1)*50;
     result.y1 := (ref+1)*50;
end;

function Node.derivedlinkage(ref : longint) : imagesqr;
{
 Returns the 4 coords of the rectanlg the line is drawn in - reqs radius
}
begin
     result.x1 := (ref+1)*50;
     result.y1 := (ref+1)*50;
end;

function FractalNode.derivedimage(ref : longint) : imagesqr;
{ Returns the 2 coords of the centre of the image

}
begin
     result.x1 := (ref+1)*50;
     result.y1 := (ref+1)*50;
end;

function FractalNode.derivedlinkage(ref : longint) : imagesqr;
{
 Returns the 4 coords of the rectanlg the line is drawn in - reqs radius
}
begin
     result.x1 := (ref+1)*50;
     result.y1 := (ref+1)*50;
end;

constructor GenericNode.create(lLinks,lsize : longint);
{Creates a Node with 'lSize' of data and 'lLinks' pointing away}
begin
     inherited createLinked(lLinks);

     getmem(Data,lSize);
     lDataSize := lSize;
end;

destructor GenericNode.destroy;
begin

     inherited destroy;
end;

procedure GenericNode.Free;
begin

end;

constructor TypedNode.create(lLinks : longint);
begin
     inherited createLinked(lLinks);

end;

destructor TypedNode.destroy;
begin

     inherited destroy;
end;

procedure TypedNode.Free;
begin
     inherited free;
end;

constructor LongintNode.create(lLinks : longint);
begin
     inherited create(lLinks);

end;

destructor LongintNode.destroy;
begin

     inherited destroy;
end;

procedure LongintNode.Free;
begin
     inherited free;
end;

constructor RealNode.create(lLinks : longint);
begin
     inherited create(lLinks);

end;

destructor RealNode.destroy;
begin

     inherited destroy;
end;

procedure RealNode.Free;
begin
     inherited free;
end;

constructor ObjectNode.create(lLinks : longint);
begin
     inherited create(lLinks);

end;

destructor ObjectNode.destroy;
begin

     inherited destroy;
end;

procedure ObjectNode.Free;
begin
     inherited free;
end;

initialization
begin
     NodeMarker := 1;
     LinkageRef := 1;

     TwoDimensions.links := 4;

end;
end.
