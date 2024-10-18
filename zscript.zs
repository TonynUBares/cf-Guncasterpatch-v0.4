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

 override void OnRegister()
 {
  if(level.LevelName ~== "TitleMap") {return;}
 }

 override void WorldThingDamaged(WorldEvent e)
 {
  if(!e.thing || !e.thing.bISMONSTER || e.thing.health > 0 || 
     (e.DamageSource && !e.DamageSource.player)) {return;}

  int spawnitemflags = SXF_ABSOLUTEVELOCITY|SXF_TRANSFERPOINTERS|SXF_TRANSFERSPRITEFRAME;
  int spawnitemflags2 = SXF_CLIENTSIDE|SXF_SETTARGET|SXF_ORIGINATOR;
  string setter = "CFCsetter";
  int whichspecie = e.thing.CountInv("IsCFSpecies");

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
  else {whichspecie = random(1,SpecieCheck.Size());}

  switch(e.DamageType)
   {
    Case 'MidasCloseCombat':   Case 'SuperMidasCloseCombat':   
    Case 'MidasShoelaces':   Case 'SuperMidasShoelaces':  
      string s = "Midas_Statue_"..StatueNames[whichspecie-1];    bool b; actor a;
      [b,a] = e.thing.A_SpawnItemEx(s,0,0,0,e.thing.vel.x,e.thing.vel.y,e.thing.vel.z,0,spawnitemflags);
      if(a)
       {
        a.Scale.x = e.thing.Scale.x;
        a.Scale.y = e.thing.Scale.y;
        a.bNODAMAGE = true;
        a.GiveInventory("CFCtempinvul",1); //avoids the statue to be insta-destroyed
       }
      e.thing.A_NoBlocking();
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

