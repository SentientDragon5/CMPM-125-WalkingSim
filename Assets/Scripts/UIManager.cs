using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class UIManager : MonoBehaviour
{
    public List<Canvas> menus;
    public int current_menu;
    public List<UnityEvent> onEnterMenu;
    public List<UnityEvent> onExitMenu;
    int hud = 2;
    int pause = 3;

    void Awake()
    {
        for (int i = 0; i < menus.Count; i++)
        {
            menus[i].enabled = false;
            onExitMenu[i].Invoke();
        }
        menus[current_menu].enabled = true;
        onEnterMenu[current_menu].Invoke();
    }

    public void OpenMenu(int index)
    {
        onExitMenu[current_menu].Invoke();
        menus[current_menu].enabled = false;
        current_menu = index;
        menus[current_menu].enabled = true;
        onEnterMenu[current_menu].Invoke();
    }
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Tab) || Input.GetKeyDown(KeyCode.Escape))
        {
            if (current_menu == hud)
                OpenMenu(pause);
            else if (current_menu == pause)
                OpenMenu(hud);
        }
    }


    public void SetTimeScale(float t) => Time.timeScale = t;
    public void SetCursorHide(bool hide) => Cursor.lockState = hide ? CursorLockMode.Locked : CursorLockMode.Confined;

    public void Quit() => Application.Quit();
}
