version "4.10"

Class ClusterCaster : EventHandler
{
 static const string StatueNames[] = {"Zombieman","ShotgunGuy","ChaingunGuy","Pimp","Demon","Demon","LostSoul",
        "Cacodemon","Painis","Arach","Fatality","Agitation","Hellknight","BaronOfHell","Vile","Mastermind",
        "Cyberdemon","WolfSS"};

 static const string SpecieCheck[] = {"Zombieman","ShotgunGuy","ChaingunGuy","DoomImp","Demon","Spectre",
        "LostSoul","Cacodemon","PainElemental","Arachnotron","Fatso","Revenant","Hellknight","BaronOfHell",
        "Archvile","SpiderMastermind","Cyberdemon","WolfensteinSS"};

 static const string SpawnerNames[] = {"CFZombieSpawner","CFShotgunGuySpawner","CFChaingunnerSpawner",
	"CFImpSpawner","CFDemonSpawner","CFSpectreSpawner","CFSoulSpawner","CFCacoSpawner","CFElementalSpawner",
	"CFArachnoSpawner","CFMancubusSpawner","CFRevenantSpawner","CFKnightSpawner","CFBaronSpawner",
	"CFVileSpawner","CFMastermindSpawner","CFCyberSpawner","CFNaziSpawner"};

 int spawnertype,spindex;
 Array<int> SpecieAmount;
 Array<int> SpawneeTids;
 Array<string> RealSpawnerNames;

 override void OnRegister()
 {
  if(level.LevelName ~== "TitleMap") {return;}
  spindex=0;
  spawnertype = CVar.GetCvar("cf_spawnerpro").GetInt();
  int f;
  while(f < SpawnerNames.Size()) {RealSpawnerNames.Push(SpawnerNames[f]); f++;}
 }

 override void WorldThingSpawned(WorldEvent e)
 {
  if(spawnertype==4)
  {
   if(!e.thing) {return;}
   if(!e.thing.bISMONSTER && e.thing.GetParentClass().GetClassName() == 'CFMonsterSpawnerBase')
   {
     SpecieAmount.Push(RealSpawnerNames.Find(e.thing.GetClassName()));
     SpawneeTids.Push(0);
     e.thing.GiveInventory("CFproSpawnerfix",1);
     let ad = CFproSpawnerfix(e.thing.FindInventory("CFproSpawnerfix"));
     if(ad) {ad.tidindex = spindex;}
     spindex++;
   }

   else if(e.thing.bISMONSTER) {e.thing.GiveInventory("CFproSpawnerFix2",1);}
  }

  else
  {
   if(!e.thing || !e.thing.bISMONSTER || e.thing.GetParentClass().GetClassName() == 'CFMonsterSpawnerBase') {return;}
 
   int x=0; 
   while(x < SpecieCheck.Size())
    {
     if(e.thing && e.thing.CountInv("IsCF"..SpecieCheck[x])) 
      {
       e.thing.GiveInventory("CFSpecies",x+1); 
       break;
      }
     x++;
    }
  }
 }

 override void WorldThingDamaged(WorldEvent e)
 {
  if(!e.thing || !e.thing.bISMONSTER || e.thing.health > 0 || //e.thing.CountInv("IsBoss") ||
      (e.DamageSource && !e.DamageSource.player)) {return;}

  int spawnitemflags = SXF_ABSOLUTEVELOCITY|SXF_TRANSFERPOINTERS|SXF_TRANSFERSPRITEFRAME;
  int spawnitemflags2 = SXF_CLIENTSIDE|SXF_SETTARGET|SXF_ORIGINATOR;
  string setter = "CFCsetter";
  int whichspecie = e.thing.CountInv("CFSpecies");

  if(whichspecie) //summoned monsters have no IsCF item
   {
    class<Actor> cls = "Guncast"..SpecieCheck[whichspecie-1];
    if(cls)
    {
     DropItem dropped = GetDefaultByType(cls).GetDropItems();
     if(dropped != null)
      {
       while(dropped != null)
        {
         e.thing.A_DropItem(dropped.name,1,dropped.probability);
         dropped = dropped.Next;
        }
      }
    }
   }

  switch(e.DamageType)
   {
    Case 'MidasCloseCombat':   Case 'SuperMidasCloseCombat':   
    Case 'MidasShoelaces':   Case 'SuperMidasShoelaces':  
      if(!whichspecie || whichspecie > SpecieCheck.Size()) {whichspecie = random(0,SpecieCheck.Size()-1);}
      string s = "Midas_Statue_"..StatueNames[whichspecie-1];    bool b; actor a;
      [b,a] = e.thing.A_SpawnItemEx(s,0,0,0,e.thing.vel.x,e.thing.vel.y,e.thing.vel.z,0,spawnitemflags);
      if(a)
       {
        a.Scale.x = e.thing.Scale.x;
        a.Scale.y = e.thing.Scale.y;
        a.bNODAMAGE = true;
        a.GiveInventory("CFCtempinvul",1); //avoids the statue to be insta-destroyed
       }
      e.thing.Destroy();
      break;

    Case 'Crow':
      e.thing.A_SpawnItemEx("FlockOfCrows",random(35,-35),random(35,-35),0,0,0,0,0,SXF_TRANSFERPOINTERS);
      e.thing.A_SpawnItemEx("FlockOfCrows",random(35,-35),random(35,-35),0,0,0,0,0,SXF_TRANSFERPOINTERS);
      e.thing.A_SpawnItemEx("FlockOfCrows",random(35,-35),random(35,-35),0,0,0,0,0,SXF_TRANSFERPOINTERS);
      break;
     
    Case 'Meteorfist': 
      e.thing.A_FaceTarget(); e.thing.A_ChangeVelocity(frandom(-7.0,-11.0),0,frandom(4.0,8.0),CVF_RELATIVE);
    Case 'Lightning':   Case 'LightningBlue':   Case 'Fire':
      e.thing.ACS_NamedExecuteAlways("Extra Crispy");
      e.thing.A_SpawnItemEx("FlamingDeath",flags:spawnitemflags2);
      e.thing.GiveInventory(setter,1);
      DeathSetter(e.thing,1);
      break;

    Case 'Tiberium': 
      e.thing.ACS_NamedExecuteAlways("Toxic Avenger");
      e.thing.A_SpawnItemEx("TiberiumDeath",flags:spawnitemflags2);
      e.thing.GiveInventory(setter,1);
      DeathSetter(e.thing,1);
      break;

    Case 'BlueTiberium':
      e.thing.ACS_NamedExecuteAlways("Blue Oyster Cult");
      e.thing.A_SpawnItemEx("BlueTiberiumDeath",flags:spawnitemflags2);
      e.thing.GiveInventory(setter,1);
      DeathSetter(e.thing,1);
      break;

    Case 'Acid': 
      e.thing.bSOLID = false;
      e.thing.A_SetTics(-1);
      e.thing.A_Startsound("Gumpop/Expand",6);
      e.thing.GiveInventory(setter,1);
      DeathSetter(e.thing,2);
   }
  
 }

  void DeathSetter(actor deadguy, int type)
  {
   let dtype = CFCsetter(deadguy.FindInventory("CFCsetter"));
   if(dtype) {dtype.user_deathtype = type;}
  }  
}


class CFproSpawnerfix : Inventory
{
 Default
 {
  Inventory.Amount 1;
  Inventory.MaxAmount 1;
 }

 int tidindex;
 int usertid;
 EventHandler handler;

 States
 {
  Held:
	TNT1 A 1;
  HeldLoop:
	TNT1 A 20 
	{
	 let handler = ClusterCaster(EventHandler.Find("ClusterCaster"));
	 if(!owner || !handler) {return;}
	 usertid = owner.ACS_ScriptCall("prospawnerfix");
	 if(usertid) 
	 {
	  handler.SpawneeTids[tidindex] = usertid; 
	  self.Destroy();
	 }
	}
	Loop;
 } 
}

class CFproSpawnerfix2 : Inventory
{
 Default
 {
  Inventory.Amount 1;
  Inventory.MaxAmount 1;
 }

 int togive;

 States
 {
  Held:
	TNT1 A 1;
  HeldLoop:
	TNT1 A 20 
	{
	 let handler = ClusterCaster(EventHandler.Find("ClusterCaster"));
	 if(!owner || !owner.tid || !handler) {return;} 

	 togive = handler.SpawneeTids.Find(owner.tid);
	 if(togive != handler.SpawneeTids.Size())
	 {
	  owner.GiveInventory("CFSpecies",handler.SpecieAmount[togive]+1);
	  self.Destroy();
	 }
	}
	Loop;
 } 
}

class CFSpecies : Inventory
{
 Default
 {
  Inventory.Amount 1;
  Inventory.MaxAmount 18;
 }
}

class CFCtempinvul : Inventory
{
 Default
 {
  Inventory.Amount 1;
  Inventory.MaxAmount 1;
 }

 States
 {
  Held:
	TNT1 A 70;
	TNT1 A 0 {owner.bNODAMAGE = false;}
	Stop;
 }
}


class CFCsetter : Inventory
{
 Default
 {
  Inventory.Amount 1;
  Inventory.MaxAmount 1;
 }

 int user_deathtype;
 int acidtrip;

 States
 {
  Held:
	TNT1 A 1;
	TNT1 A 1 A_JumpIf(user_deathtype == 2,"HeldAcid");
  HeldMeltWait:
	TNT1 A 5 
	{ 
	 if(owner && (owner.CurState.Tics == -1 || !owner.CurState.NextState)) {SetStateLabel("HeldMeltLoop");}
	}
	Loop;
  HeldMeltLoop:
	TNT1 A 1 
	{
	 if(owner)
	  {
	   if(owner.Scale.x > 1.35) {self.Destroy(); return;}
	   owner.Scale.x = owner.Scale.x + frandom(0.002,0.003);
	   owner.Scale.y = owner.Scale.y - frandom(0.003,0.004);
	  }
	}
	Loop;

  HeldAcid:
	TNT1 A 1
	{
	 if(owner)
	  {
	    owner.Scale.x = owner.Scale.x + frandom(0.01,0.025);
	    acidtrip++;
	    if(acidtrip >= 35) 
	     {
	      owner.A_Startsound("Gumpop/Pop",6);
	      owner.SetStateLabel("XDeath");
	      self.Destroy(); return;
	     }
	  }
	}
	Loop;
 }
}


